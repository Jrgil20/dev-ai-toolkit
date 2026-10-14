#!/usr/bin/env bash
# AI-First Security Audit - Automated Local Reconnaissance Script
# Scans TypeScript/Node.js/React/Expo/Supabase/Docker projects for common AI-generated security flaws.

set -euo pipefail

TARGET_DIR="${1:-.}"
echo "=================================================================="
echo "[*] AI-First Security Auditor - Reconnaissance Scan"
echo "[*] Target Directory: $(realpath "$TARGET_DIR")"
echo "=================================================================="

echo ""
echo "[1/6] Scanning for Exposed Secrets in Public Frontend Env Prefixes..."
grep -rnE "(VITE_|EXPO_PUBLIC_|NEXT_PUBLIC_|REACT_APP_)[A-Z0-9_]*(SECRET|KEY|PRIVATE|SERVICE_ROLE|PASSWORD|TOKEN|DATABASE_URL)" "$TARGET_DIR" \
  --exclude-dir={node_modules,.git,dist,build,.next,.expo} 2>/dev/null || echo "  [+] No obvious public-prefixed secret leaks found."

echo ""
echo "[2/6] Scanning for Hardcoded Credentials, JWTs, and Private Keys..."
grep -rnE "(eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9|SUPABASE_SERVICE_ROLE|postgres://[^[:space:]]+:[^[:space:]]+@|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)" "$TARGET_DIR" \
  --exclude-dir={node_modules,.git,dist,build,.next,.expo} \
  --exclude="*.lock" --exclude="package-lock.json" 2>/dev/null || echo "  [+] No hardcoded JWTs, DB URIs, or private keys detected in source."

echo ""
echo "[3/6] Scanning for Unsafe TypeScript Assertions & Missing Boundary Validation..."
grep -rnE "(req\.(body|query|params)[[:space:]]+as[[:space:]]+[A-Z]|JSON\.parse\([^)]+\)[[:space:]]+as[[:space:]]+)" "$TARGET_DIR" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir={node_modules,.git,dist,build} 2>/dev/null || echo "  [+] No raw 'req.body as Type' casts detected."

echo ""
echo "[4/6] Scanning for Permissive CORS, Eval, and Dangerous DOM/SQL Patterns..."
grep -rnE "(origin:[[:space:]]*['\"]\*['\"]|cors\(\)|dangerouslySetInnerHTML|eval\(|new Function\(|query\([[:space:]]*\`[^\`]*\$\{)" "$TARGET_DIR" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --exclude-dir={node_modules,.git,dist,build} 2>/dev/null || echo "  [+] No permissive CORS, raw template SQL, or eval() patterns found."

echo ""
echo "[5/6] Scanning SQL Migrations for Permissive RLS Policies (USING (true))..."
grep -rnE "(USING[[:space:]]*\([[:space:]]*true[[:space:]]*\)|WITH CHECK[[:space:]]*\([[:space:]]*true[[:space:]]*\)|DISABLE ROW LEVEL SECURITY)" "$TARGET_DIR" \
  --include="*.sql" \
  --exclude-dir={node_modules,.git} 2>/dev/null || echo "  [+] No 'USING (true)' or disabled RLS statements found in .sql files."

echo ""
echo "[6/6] Auditing NPM Dependencies for Known CVEs..."
if [ -f "$TARGET_DIR/package.json" ]; then
  (cd "$TARGET_DIR" && npm audit --production --audit-level=moderate || true)
else
  echo "  [-] No package.json found at root."
fi

echo ""
echo "=================================================================="
echo "[*] Recon scan complete. Feed findings into the Risk Matrix."
echo "=================================================================="
