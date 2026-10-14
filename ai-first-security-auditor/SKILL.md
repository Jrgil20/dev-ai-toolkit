---
name: ai-first-security-auditor
description: Audit and remediate security vulnerabilities in AI-generated (vibe-coded or assistant-built) projects where security was relegated during rapid development. Use when the user asks to audit, harden, review, or fix security in AI-first codebases, MVPs, or TypeScript, Node.js, React, Expo, PostgreSQL, Supabase, and Docker stacks, providing a CVE and CWE Risk Matrix along with direct code remediation.
---

# AI-First Security Auditor

Perform deep-dive security audits and direct code remediation on software projects generated intensively with AI coding assistants where security controls, architectural boundaries, and access policies were bypassed or neglected.

## When to Use

- Auditing a repository, module, or MVP built rapidly with AI assistants (Cursor, Copilot, v0, Bolt, etc.).
- Hardening projects where database policies (such as Supabase RLS), runtime input validation, or authentication checks are missing or permissive.
- Reviewing dependencies for AI-hallucinated packages (slopsquatting) or outdated versions with active CVEs.
- Refactoring leaky AI-generated code back into secure Clean or Hexagonal Architecture boundaries with strict runtime validation.
- Generating a structured CVE/CWE Risk Matrix followed immediately by production-ready remediation patches.

## Core Audit and Remediation Workflow

### Step 1: Execute Static Reconnaissance and Dependency Audit

Begin by inspecting the project structure, environment configurations, and dependency manifests. When operating in a local Linux environment or reviewing repository files, run or instruct the user to run `scripts/recon_audit.sh` to extract high-risk signals.

Focus reconnaissance on four primary failure modes of AI-assisted generation:

- **Client-Side Secret and Key Leakage:** Scan for privileged keys (`SERVICE_ROLE_KEY`, database URIs, private API keys, JWT secrets) exposed in client bundles via public prefixes (`VITE_`, `EXPO_PUBLIC_`, `NEXT_PUBLIC_`) or hardcoded in source files and Git history.
- **Supply Chain and Slopsquatting Risks:** Inspect `package.json`, `package-lock.json`, `pnpm-lock.yaml`, and `Dockerfile` base images. Verify that every package actually exists in the official registry, is actively maintained, and has no known CVEs (`npm audit`).
- **Database and BaaS Over-Exposure (Supabase / PostgreSQL):** Identify tables accessed directly from the frontend client using an anonymous key where Row Level Security (RLS) is disabled or configured with permissive policies (`USING (true)`).
- **Illusion of Type Safety at Boundaries:** Locate controllers, API routes, Edge Functions, and primary adapters that use TypeScript `as MyType` type assertions or interfaces on `req.body`, `req.query`, or external webhooks without runtime schema validation (e.g., `Zod`).

### Step 2: Enforce Architectural Boundaries (Clean / Hexagonal Hardening)

AI assistants frequently flatten architectural layers for convenience. Correct these structural vulnerabilities directly:

- **Primary Adapters (Controllers / API Routes / RPC):** Enforce strict runtime schema parsing (`Zod` with `.strict()` to prevent Mass Assignment / CWE-915) before data ever reaches an Application Use Case.
- **Domain Layer (Entities & Value Objects):** Ensure domain invariants are enforced inside Value Object constructors rather than relying on frontend checks.
- **Secondary Adapters (Repositories / External Services):** Parameterize all raw SQL queries to eliminate SQL Injection (CWE-89). Strip sensitive fields (password hashes, internal tokens, metadata) using explicit Data Transfer Objects (DTOs) before returning responses to avoid Excessive Data Exposure (API3:2023 / CWE-213).

Consult `references/remediation_patterns.md` for drop-in code templates covering Zod boundary validation, Supabase RLS locking, Express/Fastify security headers, and multi-stage rootless Dockerfiles.

### Step 3: Build the CVE / CWE and OWASP Risk Matrix

Before applying or outputting code patches, present a concise, high-signal Risk Matrix categorizing every identified vulnerability. Do not output vague warnings; anchor every finding to its exact file, line or component, CWE/CVE identifier, severity, and remediation action.

Use the following Markdown table structure:

| ID | Severity | Component / File | Vulnerability & Vector | CVE / CWE / OWASP | Remediation Applied |
|---|---|---|---|---|---|
| SEC-01 | Critical (P0) | `src/config/supabase.ts` | SUPABASE_SERVICE_ROLE_KEY bundled via EXPO_PUBLIC_ prefix | CWE-798 / API2:2023 | Migrated privileged calls to backend Edge Function; rotated key and restricted client to anon key with RLS |
| SEC-02 | High (P1) | `supabase/migrations/01_init.sql` | Table orders missing Row Level Security; full read/write via PostgREST | CWE-284 / BOLA (API1:2023) | Enabled RLS and added strict auth.uid() = user_id policies for SELECT, INSERT, UPDATE |
| SEC-03 | High (P1) | `package.json` (jsonwebtoken < 9.0.0) | Vulnerable dependency allowing signature verification bypass | CVE-2022-23529 | Upgraded jsonwebtoken to ^9.0.2 and pinned algorithm to RS256 |

### Step 4: Execute Direct Code Remediation

Operate in **Direct Remediation Mode** by default. Never stop at merely pointing out a flaw:

- **Rewrite Vulnerable Code:** Provide the complete, drop-in replacement code for every vulnerable file identified in the Risk Matrix.
- **Generate SQL Hardening Migrations:** When auditing Supabase or PostgreSQL schemas, write the complete SQL migration script (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY; CREATE POLICY ...`) to lock down every exposed table, view, and storage bucket.
- **Harden Infrastructure Configs:** Rewrite permissive CORS configurations (`origin: '*'`), add rate limiting middlewares, and harden `Dockerfile` and `docker-compose.yml` files (non-root user, pinned image digests, dropped Linux capabilities, no secrets in `ARG` or `ENV` build layers).
- **Provide Verification Commands:** Include a short block of `curl`, SQL, or test commands at the end so the engineer can immediately verify that the exploit vector is closed.

## Gotchas

- **TypeScript Interfaces Disappear at Runtime:** Never accept `const body = req.body as UserInput` as a valid security control. AI assistants write this constantly. Always replace it with `const body = UserInputSchema.parse(req.body)`.
- **Supabase RLS Enabled Without Policies Means Deny-All, Not Secure-By-Magic:** Conversely, AI assistants often add `CREATE POLICY "Enable all" ON table FOR ALL USING (true);` to "fix" permission errors during rapid prototyping. Treat `USING (true)` on sensitive tables as a P0 Critical vulnerability.
- **Views Bypass RLS by Default in PostgreSQL (< 15):** When auditing PostgreSQL or Supabase views created by AI, ensure `WITH (security_invoker = true)` is explicitly set on the view definition so underlying table RLS policies are respected.
- **Git History Persistence:** Removing a leaked secret from `.env` or source code does not remove it from `.git` history. Always instruct the user to rotate the compromised credential immediately and provide the `git filter-repo` or `gitleaks` verification step.
