#!/usr/bin/env bash
# Tests for skills/agy/scripts/agy-run.sh.
# Run: bash tests/agy_run_test.sh   (no network, no real agy: a stub replaces it)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/skills/agy/scripts/agy-run.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0
failed=0
OUT=""
ERR=""
CODE=0

mkdir -p "$WORK/bin"
cat >"$WORK/bin/agy" <<'STUB'
#!/usr/bin/env bash
if [ "${STUB_SLEEP:-0}" != 0 ]; then sleep "$STUB_SLEEP"; fi
if [ "${STUB_DENY:-0}" = 1 ]; then
  # Real agy 1.5.9 output when a headless tool permission is auto-denied: stderr only, exit 0.
  echo 'jetski: no output produced — a tool required the "mcp" permission that headless mode cannot prompt for, so it was auto-denied.' >&2
  exit 0
fi
[ -n "${STUB_STDERR:-}" ] && echo "$STUB_STDERR" >&2
echo "ARGS: $*"
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$WORK/bin/agy"
echo '{"model":"x"}' >"$WORK/no-provider.json"
echo '{"modelProvider":"gemini"}' >"$WORK/ok.json"

run() {  # run <env assignments...> -- <wrapper args...>: sets OUT, ERR and CODE
  local envs=()
  while [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  OUT="$(env -u GEMINI_API_KEY -u AGY_ALLOW_OAUTH -u AGY_HARD_TIMEOUT -u AGY_SETTINGS_FILE \
    PATH="$WORK/bin:$PATH" "${envs[@]}" bash "$SCRIPT" "$@" 2>"$WORK/stderr")"
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

# Missing API key: refuses before calling agy.
run AGY_SETTINGS_FILE="$WORK/ok.json" -- -p hi
check "no key exits 64" [ "$CODE" -eq 64 ]
check "no key explains GEMINI_API_KEY" grep -q "GEMINI_API_KEY is not set" <<<"$ERR"
check "no key never runs agy" [ -z "$OUT" ]

# Key present but settings are not in API-key mode.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/no-provider.json" -- -p hi
check "no provider exits 64" [ "$CODE" -eq 64 ]
check "no provider explains modelProvider" grep -q 'modelProvider is not "gemini"' <<<"$ERR"
check "no provider never runs agy" [ -z "$OUT" ]

# Missing settings file behaves like a missing provider.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/missing.json" -- -p hi
check "missing settings exits 64" [ "$CODE" -eq 64 ]

# Refusal message tells the user how to opt in to the personal login.
run AGY_SETTINGS_FILE="$WORK/ok.json" -- -p hi
check "refusal mentions AGY_ALLOW_OAUTH" grep -q "AGY_ALLOW_OAUTH=1" <<<"$ERR"

# Explicit opt-in: runs agy with the personal login and warns on stderr.
run AGY_ALLOW_OAUTH=1 AGY_SETTINGS_FILE="$WORK/no-provider.json" -- -p hi
check "oauth opt-in exits 0" [ "$CODE" -eq 0 ]
check "oauth opt-in runs agy" [ "$OUT" = "ARGS: -p hi --print-timeout 870s" ]
check "oauth opt-in warns" grep -q "warning: using the personal Google login" <<<"$ERR"

# Any value other than 1 is not an opt-in.
run AGY_ALLOW_OAUTH=yes AGY_SETTINGS_FILE="$WORK/no-provider.json" -- -p hi
check "non-1 opt-in exits 64" [ "$CODE" -eq 64 ]

# API-key mode configured: no warning even if the opt-in is also set.
run GEMINI_API_KEY=fake AGY_ALLOW_OAUTH=1 AGY_SETTINGS_FILE="$WORK/ok.json" -- -p hi
check "api-key mode does not warn" [ -z "$ERR" ]

# Valid config: forwards args and injects --print-timeout (hard - 30).
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" -- -p hi --model m
check "valid config exits 0" [ "$CODE" -eq 0 ]
check "valid config injects print-timeout" [ "$OUT" = "ARGS: -p hi --model m --print-timeout 870s" ]

# A caller-provided --print-timeout is kept as is, in both spellings.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" -- -p hi --print-timeout 2m
check "explicit print-timeout kept" [ "$OUT" = "ARGS: -p hi --print-timeout 2m" ]
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" -- -p hi --print-timeout=3m
check "explicit print-timeout= kept" [ "$OUT" = "ARGS: -p hi --print-timeout=3m" ]

# agy failures propagate their exit code.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" STUB_EXIT=3 -- -p hi
check "agy exit code propagates" [ "$CODE" -eq 3 ]
check "agy failure is reported" grep -q "agy exited with code 3" <<<"$ERR"

# A headless permission denial exits 0 in agy; the wrapper turns it into 65.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" STUB_DENY=1 -- -p hi
check "permission denial exits 65" [ "$CODE" -eq 65 ]
check "permission denial keeps agy message" grep -q "jetski: no output produced" <<<"$ERR"
check "permission denial explains allow rule" grep -q "mcp(<server>/<tool>)" <<<"$ERR"

# Other agy stderr output is still passed through on success.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" STUB_STDERR="some agy notice" -- -p hi
check "stderr passthrough exits 0" [ "$CODE" -eq 0 ]
check "stderr passthrough keeps text" grep -q "some agy notice" <<<"$ERR"
check "stdout still forwarded" [ "$OUT" = "ARGS: -p hi --print-timeout 870s" ]

# Invalid hard timeout is rejected.
run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" AGY_HARD_TIMEOUT=abc -- -p hi
check "invalid hard timeout exits 64" [ "$CODE" -eq 64 ]

# A hung agy is killed by the hard timeout (slow: ~61 s; skip with AGY_TEST_FAST=1).
if [ "${AGY_TEST_FAST:-0}" != 1 ]; then
  run GEMINI_API_KEY=fake AGY_SETTINGS_FILE="$WORK/ok.json" AGY_HARD_TIMEOUT=61 STUB_SLEEP=200 -- -p hi
  check "hang exits 124" [ "$CODE" -eq 124 ]
  check "hang mentions issue 318" grep -q "antigravity-cli#318" <<<"$ERR"
fi

echo "agy_run_test: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
