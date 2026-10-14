# Direct Remediation Patterns for AI-First Projects

Use these battle-tested templates when remediating vulnerabilities introduced during rapid AI-assisted development.

## 1. Runtime Boundary Validation & Mass Assignment Prevention (TypeScript + Zod)

### Vulnerable AI Pattern (CWE-20 / CWE-915)

AI assistants frequently trust TypeScript compile-time types on incoming requests and pass the entire payload directly to the ORM or database client:

```typescript
// VULNERABLE: Type assertion disappears at runtime; allows mass assignment (e.g., injecting role: 'admin')
interface UpdateProfileDto {
  fullName: string;
  bio?: string;
}

app.put('/api/profile', async (req, res) => {
  const data = req.body as UpdateProfileDto;
  await db.users.update({ where: { id: req.user.id }, data });
  res.json({ ok: true });
});
```

### Direct Remediation

Enforce `.strict()` Zod validation at the Primary Adapter boundary and map explicitly to a Domain command:

```typescript
import { z } from 'zod';
import { Request, Response, NextFunction } from 'express';

// .strict() rejects any unknown fields (e.g., role, is_verified, balance)
export const UpdateProfileSchema = z.object({
  fullName: z.string().trim().min(2).max(100),
  bio: z.string().trim().max(500).optional(),
}).strict();

export type UpdateProfileInput = z.infer<typeof UpdateProfileSchema>;

export const validateBody = <T>(schema: z.ZodSchema<T>) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json({
        error: 'Invalid request payload',
        details: result.error.issues.map(i => ({ path: i.path.join('.'), code: i.code })),
      });
    }

    req.body = result.data;
    next();
  };
};
```

## 2. Supabase / PostgreSQL Row Level Security (RLS) Hardening

### Vulnerable AI Pattern (CWE-284 / OWASP API1:2023 BOLA)

AI coding assistants often create tables without enabling RLS, or bypass RLS errors during prototyping by adding `USING (true)`:

```sql
-- VULNERABLE: Anyone with the public anon key can read, modify, or delete all records
CREATE TABLE public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  amount numeric NOT NULL,
  currency text NOT NULL
);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access for MVP" ON public.transactions FOR ALL USING (true);
```

### Direct Remediation

Drop permissive policies, force RLS even for table owners, bind operations strictly to `(select auth.uid())`, and secure views with `security_invoker`:

```sql
-- REMEDIATION: Strict tenant isolation and privilege scoping
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access for MVP" ON public.transactions;

-- Revoke default public mutations if only specific operations should be allowed
REVOKE ALL ON public.transactions FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.transactions TO authenticated;

-- Note: Wrapping auth.uid() in (select auth.uid()) caches the evaluation per statement (performance + security)
CREATE POLICY "transactions_select_own"
  ON public.transactions
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "transactions_insert_own"
  ON public.transactions
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = user_id AND amount > 0);

CREATE POLICY "transactions_update_own"
  ON public.transactions
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id AND amount > 0);

-- Ensure PostgreSQL Views respect the caller's RLS policies (PostgreSQL 15+)
ALTER VIEW IF EXISTS public.user_transaction_summary SET (security_invoker = true);
```

## 3. Node.js / Express API Hardening (CORS, Helmet, Rate Limiting)

### Vulnerable AI Pattern (CWE-942 / CWE-770)

Default `app.use(cors())` allowing any origin and zero rate limiting on authentication or compute-heavy routes.

### Direct Remediation

Apply explicit origin allowlists, security headers, payload size caps, and tiered rate limiters:

```typescript
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';

const app = express();

// 1. Security Headers
app.use(helmet());
app.disable('x-powered-by');

// 2. Strict CORS Allowlist
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '').split(',').filter(Boolean);
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Origin not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  credentials: true,
}));

// 3. Payload Size Limit (Prevents Memory Exhaustion / DoS)
app.use(express.json({ limit: '100kb' }));

// 4. Tiered Rate Limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});

const strictAuthLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many authentication attempts.' },
});

app.use('/api/', apiLimiter);
app.use('/api/auth/', strictAuthLimiter);
```

## 4. Docker & Container Hardening

### Vulnerable AI Pattern (CWE-250)

Single-stage `FROM node:latest`, running as root, copying `.env` and `.git` into the image via `COPY . .`.

### Direct Remediation

Multi-stage build, deterministic lockfile install, minimal Alpine image, non-root node user, and read-only privileges:

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY tsconfig.json ./
COPY src ./src
RUN npm run build && npm prune --production

# Stage 2: Hardened Runtime
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Drop root privileges
USER node

COPY --from=builder --chown=node:node /app/package.json ./
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/dist ./dist

EXPOSE 3000
CMD ["node", "dist/main.js"]
```
