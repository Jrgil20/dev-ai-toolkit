#!/usr/bin/env bash
# Instala los skills y subagentes en Claude Code vía symlinks.
# El repo queda como única fuente de verdad: `git pull` actualiza todo.
#
# Uso:
#   ./install.sh                 # nivel usuario (~/.claude/)
#   ./install.sh --project       # proyecto actual (./.claude/)
#   ./install.sh --no-vendor     # omite vendor/ (copias de terceros)
#   ./install.sh --no-external   # omite external/ (submódulos de terceros, p. ej. Cloudflare)
#   ./install.sh --dry-run       # muestra qué haría, sin tocar nada
#
# Si clonaste sin --recurse-submodules, el script descarga los submódulos de
# external/ automáticamente (git submodule update --init).
#
# Política de colisión (igual que docs/agent-installation-spec.md):
#   - Si el destino ya es un symlink a este repo → se deja (OK).
#   - Si existe otra cosa con ese nombre → se omite con [WARN]; nunca se sobreescribe.
# standalone/ no se enlaza: esos skills se instalan aparte (ver su README).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$HOME/.claude"
WITH_VENDOR=1
WITH_EXTERNAL=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --project)   BASE="$(pwd)/.claude" ;;
    --no-vendor) WITH_VENDOR=0 ;;
    --no-external) WITH_EXTERNAL=0 ;;
    --dry-run)   DRY_RUN=1 ;;
    -h|--help)   sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

installed=0; skipped=0; ok=0

link() {  # link <origen> <destino> <etiqueta>
  local src="$1" dest="$2" label="$3"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "  [OK]   $label ya enlazado"; ok=$((ok + 1)); return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "  [WARN] $label: ya existe '$dest' (no apunta a este repo). Se omite."
    skipped=$((skipped + 1)); return
  fi
  if (( DRY_RUN )); then
    echo "  [DRY]  $label → $dest"
  else
    ln -s "$src" "$dest"; echo "  [NEW]  $label → $dest"
  fi
  installed=$((installed + 1))
}

echo "Instalando en: $BASE$( (( DRY_RUN )) && echo ' (dry-run)')"
(( DRY_RUN )) || mkdir -p "$BASE/skills" "$BASE/agents"

dirs=("$REPO_DIR/skills")
(( WITH_VENDOR )) && dirs+=("$REPO_DIR/vendor")

for dir in "${dirs[@]}"; do
  echo ""; echo "$(basename "$dir")/"
  for skill in "$dir"/*/; do
    [[ -f "$skill/SKILL.md" ]] || continue
    skill="${skill%/}"
    link "$skill" "$BASE/skills/$(basename "$skill")" "skill $(basename "$skill")"
  done
done

# external/: skills de terceros como submódulos git (siguen al upstream).
if (( WITH_EXTERNAL )) && [[ -f "$REPO_DIR/.gitmodules" ]]; then
  echo ""; echo "external/"
  while read -r _ sub_path; do
    [[ "$sub_path" == external/* ]] || continue
    if [[ ! -e "$REPO_DIR/$sub_path/.git" ]]; then
      if (( DRY_RUN )); then
        echo "  [DRY]  descargaría el submódulo $sub_path"; continue
      fi
      echo "  [INIT] descargando submódulo $sub_path ..."
      if ! git -C "$REPO_DIR" submodule update --init -- "$sub_path"; then
        echo "  [WARN] no se pudo descargar $sub_path (¿sin red?). Se omite."
        skipped=$((skipped + 1)); continue
      fi
    fi
    found=0
    for skill in "$REPO_DIR/$sub_path"/skills/*/ "$REPO_DIR/$sub_path"/; do
      [[ -f "$skill/SKILL.md" ]] || continue
      skill="${skill%/}"
      name="$(sed -n 's/^name:[[:space:]]*//p' "$skill/SKILL.md" | head -1)"
      link "$skill" "$BASE/skills/${name:-$(basename "$skill")}" "skill ${name:-$(basename "$skill")} ($sub_path)"
      found=1
    done
    (( found )) || echo "  [WARN] $sub_path no contiene SKILL.md"
  done < <(git -C "$REPO_DIR" config -f .gitmodules --get-regexp '^submodule\..*\.path$')
fi

echo ""; echo "adapters/claude-code/agents/"
for agent in "$REPO_DIR"/adapters/claude-code/agents/*.md; do
  name="$(basename "$agent")"
  link "$agent" "$BASE/agents/$name" "agent ${name%.md}"
done

echo ""
echo "Resumen: $installed nuevos, $ok ya estaban, $skipped omitidos por colisión."
echo "Verifica en Claude Code con: /skills  y  /agents"
