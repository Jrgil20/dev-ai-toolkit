#!/usr/bin/env bash
# AI-First Security Audit - Automated Local Reconnaissance Script
# Scans TypeScript/Node.js/React/Expo/Supabase/Docker projects for common AI-generated security flaws.
#
# Exit codes: 0 = scan completed (findings, if any, are printed above the summary)
#             2 = the target is not a readable directory, or a check could not finish;
#                 a check that could not finish is marked [!] and is never reported as clean.

set -euo pipefail

TARGET_DIR="${1:-.}"
if [[ ! -d "$TARGET_DIR" || ! -r "$TARGET_DIR" ]]; then
  echo "[!] Target is not a readable directory: $TARGET_DIR" >&2
  exit 2
fi

GREP_ERRORS="$(mktemp)"
trap 'rm -f "$GREP_ERRORS"' EXIT
INCOMPLETE_CHECKS=0

# run_check <clean-message> <grep arguments...>
# grep exit codes: 0 = matches (printed), 1 = no matches, 2 = error (unreadable files, bad pattern...).
run_check() {
  local clean_msg="$1"; shift
  local status=0
  grep -rnE "$@" 2>"$GREP_ERRORS" || status=$?
  case "$status" in
    0) ;;
    1) echo "  [+] $clean_msg" ;;
    *)
      echo "  [!] Check incomplete (grep exit $status): some files could not be scanned."
      sed 's/^/      /' "$GREP_ERRORS"
      INCOMPLETE_CHECKS=$((INCOMPLETE_CHECKS + 1))
      ;;
  esac
}

echo "=================================================================="
echo "[*] AI-First Security Auditor - Reconnaissance Scan"
echo "[*] Target Directory: $(realpath "$TARGET_DIR")"
echo "=================================================================="

echo ""
echo "[1/6] Scanning for Exposed Secrets in Public Frontend Env Prefixes..."
run_check "No obvious public-prefixed secret leaks found." \
  "(VITE_|EXPO_PUBLIC_|NEXT_PUBLIC_|REACT_APP_)[A-Z0-9_]*(SECRET|KEY|PRIVATE|SERVICE_ROLE|PASSWORD|TOKEN|DATABASE_URL)" "$TARGET_DIR" \
  --exclude-dir={node_modules,.git,dist,build,.next,.expo}

echo ""
echo "[2/6] Scanning for Hardcoded Credentials, JWTs, and Private Keys..."
run_check "No hardcoded JWTs, DB URIs, or private keys detected in source." \
  "(eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9|SUPABASE_SERVICE_ROLE|postgres://[^[:space:]]+:[^[:space:]]+@|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----)" "$TARGET_DIR" \
  --exclude-dir={node_modules,.git,dist,build,.next,.expo} \
  --exclude="*.lock" --exclude="package-lock.json"

echo ""
echo "[3/6] Scanning for Unsafe TypeScript Assertions & Missing Boundary Validation..."
run_check "No raw 'req.body as Type' casts detected." \
  "(req\.(body|query|params)[[:space:]]+as[[:space:]]+[A-Z]|JSON\.parse\([^)]+\)[[:space:]]+as[[:space:]]+)" "$TARGET_DIR" \
  --include="*.ts" --include="*.tsx" \
  --exclude-dir={node_modules,.git,dist,build}

echo ""
echo "[4/6] Scanning for Permissive CORS, Eval, and Dangerous DOM/SQL Patterns..."
# The template-SQL branch matches a literal "\${" (escaped for both bash and ERE): query(`... ${
run_check "No permissive CORS, raw template SQL, or eval() patterns found." \
  "(origin:[[:space:]]*['\"]\*['\"]|cors\(\)|dangerouslySetInnerHTML|eval\(|new Function\(|query\([[:space:]]*\`[^\`]*\\\$\{)" "$TARGET_DIR" \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --exclude-dir={node_modules,.git,dist,build}

echo ""
echo "[5/6] Scanning SQL Migrations for Permissive RLS Policies (USING (true))..."
run_check "No 'USING (true)' or disabled RLS statements found in .sql files." \
  "(USING[[:space:]]*\([[:space:]]*true[[:space:]]*\)|WITH CHECK[[:space:]]*\([[:space:]]*true[[:space:]]*\)|DISABLE ROW LEVEL SECURITY)" "$TARGET_DIR" \
  --include="*.sql" \
  --exclude-dir={node_modules,.git}

echo ""
echo "[6/6] Auditing NPM Dependencies for Known CVEs..."
if [ -f "$TARGET_DIR/package.json" ]; then
  (cd "$TARGET_DIR" && npm audit --production --audit-level=moderate || true)
else
  echo "  [-] No package.json found at root."
fi

echo ""
echo "=================================================================="
if (( INCOMPLETE_CHECKS > 0 )); then
  echo "[!] Recon scan INCOMPLETE: $INCOMPLETE_CHECKS check(s) could not finish (marked [!] above)."
  echo "=================================================================="
  exit 2
fi
echo "[*] Recon scan complete. Feed findings into the Risk Matrix."
echo "=================================================================="
