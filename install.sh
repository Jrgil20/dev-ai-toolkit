#!/usr/bin/env bash
# Instala los skills y subagentes en Claude Code vía symlinks.
# El repo queda como única fuente de verdad: `git pull` actualiza todo.
#
# Uso:
#   ./install.sh                       # nivel usuario (~/.claude/): skills generales
#   ./install.sh --project             # proyecto actual (./.claude/)
#   ./install.sh --project --stack auto            # SOLO los packs del stack detectado en el proyecto
#   ./install.sh --project --stack supabase,react  # SOLO los packs elegidos a mano
#   ./install.sh --project --stack auto --with-base  # packs + todo lo general en el proyecto
#   ./install.sh --list-stacks         # qué packs por stack existen y qué skills traen
#   ./install.sh --no-vendor           # omite vendor/ (copias de terceros)
#   ./install.sh --no-external         # omite external/ (submódulos de terceros)
#   ./install.sh --dry-run             # muestra qué haría, sin tocar nada
#
# Packs por stack (external/): skills oficiales de Supabase, Netlify y Vercel/React.
# Son para PROYECTOS QUE USAN ESA HERRAMIENTA, por eso no se instalan por defecto:
# se piden con --stack (idealmente junto con --project). Con --project --stack se
# instalan SOLO los packs en el proyecto, porque lo general ya vive en ~/.claude
# (así no aparece duplicado); --with-base lo incluye igual. Solo se descargan los
# submódulos que hacen falta. Qué skill pertenece a qué stack se define en
# .gitmodules (clave toolkit-skills = "<carpeta-del-skill>:<stack> ...").
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
STACK_ARG=""
LIST_STACKS=0
PROJECT=0
WITH_BASE=0

while (( $# )); do
  case "$1" in
    --project)     BASE="$(pwd)/.claude"; PROJECT=1 ;;
    --with-base)   WITH_BASE=1 ;;
    --no-vendor)   WITH_VENDOR=0 ;;
    --no-external) WITH_EXTERNAL=0 ;;
    --dry-run)     DRY_RUN=1 ;;
    --list-stacks) LIST_STACKS=1 ;;
    --stack)       shift; STACK_ARG="${1:-}" ;;
    --stack=*)     STACK_ARG="${1#--stack=}" ;;
    -h|--help)     sed -n '2,27p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; exit 2 ;;
  esac
  shift
done

gm() { git -C "$REPO_DIR" config -f .gitmodules "$@" 2>/dev/null || true; }

# Lista "path<TAB>skill<TAB>stack" de todos los skills declarados en external/.
external_entries() {
  [[ -f "$REPO_DIR/.gitmodules" ]] || return 0
  gm --get-regexp '^submodule\..*\.path$' | while read -r key sub_path; do
    [[ "$sub_path" == external/* ]] || continue
    name="${key#submodule.}"; name="${name%.path}"
    spec="$(gm --get "submodule.$name.toolkit-skills")"
    if [[ -z "$spec" ]]; then
      printf '%s\t*\tgeneral\n' "$sub_path"      # sin declaración: todos, como generales
    else
      for pair in $spec; do printf '%s\t%s\t%s\n' "$sub_path" "${pair%%:*}" "${pair##*:}"; done
    fi
  done
}

# Detecta stacks en el directorio actual (el proyecto donde corres el script).
detect_stacks() {
  local found=()
  local pkg=""; [[ -f package.json ]] && pkg="$(cat package.json)"
  if [[ -f supabase/config.toml ]] || grep -q '"@supabase/' <<<"$pkg" \
     || grep -qsi '^supabase' requirements.txt pyproject.toml 2>/dev/null; then found+=(supabase); fi
  if [[ -f netlify.toml || -d .netlify ]] || grep -q '"netlify-cli"\|"@netlify/' <<<"$pkg"; then found+=(netlify); fi
  if [[ -f vercel.json || -d .vercel ]] || grep -q '"vercel"' <<<"$pkg"; then found+=(vercel); fi
  if grep -q '"react"' <<<"$pkg"; then found+=(react); fi
  (IFS=,; echo "${found[*]:-}")
}

if (( LIST_STACKS )); then
  echo "Packs por stack disponibles (instálalos en proyectos que usen esa herramienta):"
  external_entries | awk -F'\t' '$3!="general"{s[$3]=s[$3] "  - " $2 "  (" $1 ")\n"} END{for(k in s) printf "\n[%s]\n%s", k, s[k]}'
  echo ""; echo "Uso: ./install.sh --project --stack auto   |   --stack supabase,netlify,vercel,react"
  exit 0
fi

STACKS="general"
if [[ "$STACK_ARG" == "auto" ]]; then
  detected="$(detect_stacks)"
  echo "Stacks detectados en $(pwd): ${detected:-ninguno}"
  [[ -n "$detected" ]] && STACKS="general,$detected"
elif [[ -n "$STACK_ARG" ]]; then
  STACKS="general,$STACK_ARG"
fi
# Con --project --stack, por defecto solo los packs (lo general ya está en ~/.claude).
STACK_ONLY=0
if (( PROJECT )) && [[ -n "$STACK_ARG" ]] && (( ! WITH_BASE )); then
  STACK_ONLY=1
  STACKS="${STACKS#general}"; STACKS="${STACKS#,}"
  if [[ -z "$STACKS" ]]; then
    echo "No se detectó ningún stack conocido en $(pwd); nada que instalar."
    echo "Elige a mano con --stack supabase,netlify,vercel,react (ver --list-stacks)."
    exit 0
  fi
fi
wants_stack() { [[ ",$STACKS," == *",$1,"* ]]; }

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

skill_name() {  # nombre declarado en el frontmatter (puede diferir de la carpeta)
  local n; n="$(sed -n 's/^name:[[:space:]]*//p' "$1/SKILL.md" | head -1 | tr -d "\"'")"
  echo "${n:-$(basename "$1")}"
}

echo "Instalando en: $BASE$( (( DRY_RUN )) && echo ' (dry-run)') · stacks: $STACKS"
(( DRY_RUN )) || mkdir -p "$BASE/skills"
(( DRY_RUN || STACK_ONLY )) || mkdir -p "$BASE/agents"

dirs=()
(( STACK_ONLY )) || dirs+=("$REPO_DIR/skills")
(( WITH_VENDOR && ! STACK_ONLY )) && dirs+=("$REPO_DIR/vendor")

for dir in "${dirs[@]+"${dirs[@]}"}"; do
  echo ""; echo "$(basename "$dir")/"
  for skill in "$dir"/*/; do
    [[ -f "$skill/SKILL.md" ]] || continue
    skill="${skill%/}"
    link "$skill" "$BASE/skills/$(basename "$skill")" "skill $(basename "$skill")"
  done
done

# external/: skills de terceros como submódulos git (siguen al upstream).
if (( WITH_EXTERNAL )); then
  declare -A needed=()            # submódulos con al menos un skill pedido
  while IFS=$'\t' read -r sub_path skill stack; do
    wants_stack "$stack" && needed["$sub_path"]=1
  done < <(external_entries)

  if (( ${#needed[@]} )); then
    echo ""; echo "external/"
    for sub_path in $(printf '%s\n' "${!needed[@]}" | sort); do
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
    done
    while IFS=$'\t' read -r sub_path skill stack; do
      wants_stack "$stack" || continue
      [[ -e "$REPO_DIR/$sub_path/.git" ]] || continue
      if [[ "$skill" == "*" ]]; then
        candidates=("$REPO_DIR/$sub_path"/skills/*/ "$REPO_DIR/$sub_path/")
      else
        candidates=("$REPO_DIR/$sub_path/skills/$skill/")
      fi
      for dir in "${candidates[@]}"; do
        [[ -f "$dir/SKILL.md" ]] || { [[ "$skill" != "*" ]] && echo "  [WARN] $sub_path: no existe skills/$skill/SKILL.md"; continue; }
        dir="${dir%/}"; name="$(skill_name "$dir")"
        link "$dir" "$BASE/skills/$name" "skill $name [$stack] ($sub_path)"
      done
    done < <(external_entries)
  fi

  if [[ "$STACKS" == "general" ]]; then
    stacks_avail="$(external_entries | awk -F'\t' '$3!="general"{print $3}' | sort -u | paste -sd, -)"
    [[ -n "$stacks_avail" ]] && echo "" && echo "  Packs por stack disponibles ($stacks_avail): solo para proyectos que usan esas herramientas." \
      && echo "  Instálalos desde el proyecto con: $REPO_DIR/install.sh --project --stack auto"
  fi
fi

if (( ! STACK_ONLY )); then
  echo ""; echo "adapters/claude-code/agents/"
  for agent in "$REPO_DIR"/adapters/claude-code/agents/*.md; do
    name="$(basename "$agent")"
    link "$agent" "$BASE/agents/$name" "agent ${name%.md}"
  done
fi

echo ""
echo "Resumen: $installed nuevos, $ok ya estaban, $skipped omitidos por colisión."
echo "Verifica en Claude Code con: /skills  y  /agents"
