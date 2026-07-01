#!/usr/bin/env bash
# Instala los skills y subagentes en Claude Code vía symlinks.
# El repo queda como única fuente de verdad: `git pull` actualiza todo.
#
# Uso:
#   ./install.sh            # instala a nivel usuario (~/.claude/)
#   ./install.sh --project  # instala en el proyecto actual (./.claude/)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--project" ]]; then
  BASE="$(pwd)/.claude"
else
  BASE="$HOME/.claude"
fi

mkdir -p "$BASE/skills" "$BASE/agents"

echo "Instalando en: $BASE"
echo ""

for skill in "$REPO_DIR"/skills/*/; do
  skill="${skill%/}"
  name="$(basename "$skill")"
  ln -sfn "$skill" "$BASE/skills/$name"
  echo "  skill → $name"
done

for agent in "$REPO_DIR"/adapters/claude-code/agents/*.md; do
  name="$(basename "$agent")"
  ln -sfn "$agent" "$BASE/agents/$name"
  echo "  agent → ${name%.md}"
done

echo ""
echo "Listo. Verifica en Claude Code con: /skills  y  /agents"
