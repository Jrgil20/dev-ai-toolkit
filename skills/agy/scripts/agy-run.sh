#!/usr/bin/env bash
# Run `agy` for delegated, non-interactive work.
# Enforces API-key mode (unless the user opted in to the personal login),
# a hard timeout, and an explicit --print-timeout.
# Usage: agy-run.sh <agy args...>
# Env:   AGY_HARD_TIMEOUT (seconds, default 900), AGY_SETTINGS_FILE (override settings path),
#        AGY_ALLOW_OAUTH=1 (user opt-in: run with the personal Google login, with a warning)
set -uo pipefail

hard="${AGY_HARD_TIMEOUT:-900}"
settings="${AGY_SETTINGS_FILE:-$HOME/.gemini/antigravity-cli/settings.json}"

die() { echo "agy-run: $1" >&2; exit "$2"; }

command -v agy >/dev/null 2>&1 || die "agy not found on PATH." 127
command -v jq >/dev/null 2>&1 || die "jq is required to check $settings." 127
[[ "$hard" =~ ^[0-9]+$ ]] && (( hard > 60 )) || die "AGY_HARD_TIMEOUT must be an integer > 60." 64

reason=""
if [ -z "${GEMINI_API_KEY:-}" ]; then
  reason="GEMINI_API_KEY is not set."
else
  provider="$(jq -r '.modelProvider // empty' "$settings" 2>/dev/null || true)"
  [ "$provider" = "gemini" ] || reason="modelProvider is not \"gemini\" in $settings."
fi

if [ -n "$reason" ]; then
  if [ "${AGY_ALLOW_OAUTH:-0}" = "1" ]; then
    echo "agy-run: warning: using the personal Google login (AGY_ALLOW_OAUTH=1; $reason) This may breach the Antigravity terms; switch to API-key mode when possible." >&2
  else
    die "$reason Delegation expects API-key mode. To accept the risk and use the personal Google login instead, the user must export AGY_ALLOW_OAUTH=1." 64
  fi
fi

args=("$@")
has_print_timeout=0
for a in "${args[@]}"; do
  [[ "$a" == --print-timeout || "$a" == --print-timeout=* ]] && has_print_timeout=1
done
(( has_print_timeout )) || args+=(--print-timeout "$((hard - 30))s")

err="$(mktemp)"
trap 'rm -f "$err"' EXIT

# stdout streams; stderr is captured so a headless permission denial can be detected.
timeout --kill-after=10 "$hard" agy "${args[@]}" </dev/null 2>"$err"
rc=$?
cat "$err" >&2

case "$rc" in
  124|137) echo "agy-run: agy did not finish within ${hard}s (possible no-TTY hang, antigravity-cli#318)." >&2 ;;
  0)
    # agy 1.5.9 exits 0 when a tool permission is auto-denied in print mode.
    if grep -qF "no output produced" "$err"; then
      echo "agy-run: agy produced no result: a tool permission was auto-denied in headless mode. The user must add a narrow allow rule in agy settings, e.g. mcp(<server>/<tool>) or mcp(<server>/*)." >&2
      rc=65
    fi
    ;;
  *) echo "agy-run: agy exited with code $rc." >&2 ;;
esac
exit "$rc"
