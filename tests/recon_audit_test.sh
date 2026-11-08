#!/usr/bin/env bash
# Tests for standalone/ai-first-security-auditor/scripts/recon_audit.sh.
# Run: bash tests/recon_audit_test.sh   (no dependencies; fixtures live in a temp dir)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/standalone/ai-first-security-auditor/scripts/recon_audit.sh"
WORK="$(mktemp -d)"
trap 'chmod -R u+rwX "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

passed=0
failed=0
OUT=""
ERR=""
CODE=0

run_scan() {  # run_scan <target>: sets OUT, ERR and CODE
  OUT="$(bash "$SCRIPT" "$1" 2>"$WORK/stderr")"
  CODE=$?
  ERR="$(cat "$WORK/stderr")"
}

check() {  # check <description> <command...>
  local desc="$1"; shift
  if "$@"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    echo "FAIL: $desc"
  fi
}
contains() { [[ "$1" == *"$2"* ]]; }
lacks() { [[ "$1" != *"$2"* ]]; }

CLEAN_MSGS=(
  "[+] No obvious public-prefixed secret leaks found."
  "[+] No hardcoded JWTs, DB URIs, or private keys detected in source."
  "[+] No raw 'req.body as Type' casts detected."
  "[+] No permissive CORS, raw template SQL, or eval() patterns found."
  "[+] No 'USING (true)' or disabled RLS statements found in .sql files."
)

# --- A missing target must fail, never report a clean scan.
run_scan "$WORK/does-not-exist"
check "missing target: exits with code 2" test "$CODE" -eq 2
check "missing target: names the path on stderr" contains "$ERR" "does-not-exist"
check "missing target: prints no clean result" lacks "$OUT" "[+]"

# --- A check whose grep fails (unreadable file) must be reported, not shown as clean.
if (( EUID != 0 )); then  # root can read mode-000 files, so the case cannot be built
  mkdir -p "$WORK/unreadable"
  echo "NEXT_PUBLIC_SERVICE_ROLE_KEY=x" > "$WORK/unreadable/.env"
  chmod 000 "$WORK/unreadable/.env"
  run_scan "$WORK/unreadable"
  check "grep error: exits with code 2" test "$CODE" -eq 2
  check "grep error: marks the check as incomplete" contains "$OUT" "[!]"
  check "grep error: shows the unreadable file" contains "$OUT" ".env"
  check "grep error: does not claim the secrets check is clean" lacks "$OUT" "${CLEAN_MSGS[0]}"
else
  echo "SKIP: grep error case (running as root)"
fi

# --- Raw template-literal SQL must be detected.
mkdir -p "$WORK/sqli"
printf '%s\n' 'db.query(`SELECT * FROM users WHERE id = ${id}`)' > "$WORK/sqli/repo.ts"
run_scan "$WORK/sqli"
check "template SQL: reports the offending line" contains "$OUT" "repo.ts:1:"
check "template SQL: does not claim the check is clean" lacks "$OUT" "${CLEAN_MSGS[3]}"

# --- Previous behavior: a clean project passes every check with exit 0.
mkdir -p "$WORK/clean"
echo "export const answer = 42;" > "$WORK/clean/index.ts"
run_scan "$WORK/clean"
check "clean project: exits 0" test "$CODE" -eq 0
for msg in "${CLEAN_MSGS[@]}"; do
  check "clean project: prints '$msg'" contains "$OUT" "$msg"
done
check "clean project: reports the missing package.json" contains "$OUT" "[-] No package.json found at root."

# --- Previous behavior: each existing check still flags its pattern; findings keep exit 0.
mkdir -p "$WORK/dirty"
echo "const k = process.env.NEXT_PUBLIC_API_KEY" > "$WORK/dirty/env.ts"
echo "-----BEGIN RSA PRIVATE KEY-----" > "$WORK/dirty/id_rsa.pem"
echo "const body = req.body as User" > "$WORK/dirty/handler.ts"
echo "eval(input)" > "$WORK/dirty/danger.js"
echo "CREATE POLICY p ON t USING (true);" > "$WORK/dirty/policy.sql"
run_scan "$WORK/dirty"
check "findings: exits 0" test "$CODE" -eq 0
for file in env.ts id_rsa.pem handler.ts danger.js policy.sql; do
  check "findings: reports $file" contains "$OUT" "$file:1:"
done
for msg in "${CLEAN_MSGS[@]}"; do
  check "findings: does not print '$msg'" lacks "$OUT" "$msg"
done

echo "$passed passed, $failed failed"
(( failed == 0 ))
