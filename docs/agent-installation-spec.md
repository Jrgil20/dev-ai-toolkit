# Especificación de Instalación Nativa Multi-Agente (Gentle-AI Matrix)

Esta especificación define el protocolo determinista para que un **agente de IA consumidor** (que incorpora `dev-ai-toolkit` como submódulo o dependencia) instale los skills de este repositorio de forma nativa en el entorno de desarrollo del usuario.

> [!NOTE]
> La matriz de rutas y detección está basada en la arquitectura de adaptadores de [Gentle-AI](https://github.com/Gentleman-Programming/gentle-ai), garantizando compatibilidad con el estándar Agent Skills (`SKILL.md`).

---

## 1. Principios del Instalador

1. **Información para el Agente:** Este documento es el contrato de conocimiento. El agente que instala el submódulo es quien inspecciona el entorno del usuario, selecciona el destino correspondiente y ejecuta las operaciones.
2. **Alcance Exclusivo de Skills:** Solo se instalan los directorios contenidos en `skills/*/`. No se intentan convertir ni enlazar adaptadores de subagentes específicos de una herramienta (`adapters/`) en clientes que no los soporten.
3. **Casos Especiales:** Carpetas en la raíz con estructura de skill como `ai-first-security-auditor/` son casos especiales de auditoría dedicada y **NO** deben ser enlazadas dentro del loop estándar de `skills/`.
4. **Política de Colisión ("Saltear con Warning"):** Si en la ruta destino ya existe un skill con el mismo nombre (sea carpeta real o symlink externo), **NUNCA** se sobreescribe. Se emite una advertencia formal y se continúa con el siguiente.
5. **Symlinks como Enlace Preferido:** Siempre que el sistema operativo y el sistema de archivos lo permitan, se crean enlaces simbólicos absolutos para que `git pull` en el submódulo mantenga los skills actualizados sin reinstalación.

---

## 2. Matriz de Detección y Rutas de Agentes

El agente instalador debe verificar las evidencias de detección en orden de precedencia. Una vez detectado el agente activo (o los agentes activos), utilizará las rutas correspondientes.

| Agente | ID Gentle-AI | Detección (Evidencia en el Sistema) | Ruta Skills Global (`$HOME`) | Ruta Skills Proyecto (`--project`) |
|---|---|---|---|---|
| **Claude Code** | `claude-code` | Carpeta `~/.claude` o binario `claude` en `$PATH` | `~/.claude/skills` | `./.claude/skills` |
| **Antigravity** | `antigravity` | Carpeta `~/.gemini/antigravity-cli`, `~/.gemini/antigravity-desktop`, `~/.gemini/antigravity` o binario `agy` | `~/.gemini/antigravity-cli/skills` *(o variante detectada)* | `./.agent/skills` |
| **Cursor** | `cursor` | Carpeta `~/.cursor` o binario `cursor` en `$PATH` | `~/.cursor/skills` | `./.cursor/skills` |
| **Windsurf** | `windsurf` | Carpeta `~/.codeium/windsurf` o binario `windsurf` | `~/.codeium/windsurf/skills` | `./.codeium/windsurf/skills` *(o `./.windsurf/skills`)* |
| **OpenCode** | `opencode` | Carpeta `~/.config/opencode` (o `$XDG_CONFIG_HOME/opencode`) o binario `opencode` | `~/.config/opencode/skills` | `./.opencode/skills` |
| **Gemini CLI** | `gemini-cli` | Carpeta `~/.gemini` o binario `gemini` en `$PATH` | `~/.gemini/skills` | `./.gemini/skills` |
| **VS Code Copilot** | `vscode-copilot` | Carpeta `~/.copilot` o binario `code` en `$PATH` | `~/.copilot/skills` | `./.github/skills` |
| **Codex** | `codex` | Carpeta `~/.codex` o binario `codex` en `$PATH` | `~/.codex/skills` | `./.codex/skills` |
| **Kimi Code** | `kimi` | Carpeta `~/.kimi-code` (actual) o `~/.kimi` (legado) | `~/.kimi-code/skills` *(legado: `~/.config/agents/skills`)* | `./.kimi/skills` |
| **Kiro IDE** | `kiro-ide` | Carpeta `~/.kiro` | `~/.kiro/skills` | `./.kiro/skills` |
| **Kilo Code** | `kilocode` | Carpeta `~/.config/kilo` | `~/.config/kilo/skills` | `./.kilo/skills` |
| **OpenClaw** | `openclaw` | Carpeta `~/.openclaw` o `~/.config/openclaw` | `~/.openclaw/skills` | `./.openclaw/skills` |
| **Trae** | `trae-ide` | Carpeta `~/.trae` | `~/.trae/skills` | `./.trae/skills` |
| **Hermes** | `hermes` | Carpeta `~/.hermes` o `~/.config/hermes` | `~/.hermes/skills` | `./.hermes/skills` |

---

## 3. Algoritmo de Instalación para el Agente Consumidor

Cuando un agente deba instalar `dev-ai-toolkit`, seguirá este procedimiento determinista:

```text
Entrada:
  - SUBMODULE_DIR: Ruta absoluta a la raíz de dev-ai-toolkit
  - SCOPE: 'global' (por defecto) o 'project' (workspace actual)

Paso 1: Identificación del Agente Destino
  1.1 Evaluar si el usuario especificó un agente explícito.
  1.2 Si no se especificó, comprobar la existencia de evidencias de detección de la Tabla 2.
  1.3 Si se detectan múltiples agentes instalados en la máquina, el agente consumidor puede:
      a) Preguntar al usuario cuál configurar.
      b) O instalar en todos los agentes detectados.

Paso 2: Resolución del Directorio Destino
  2.1 Según el SCOPE y el AGENTE, obtener TARGET_SKILLS_DIR de la Tabla 2.
  2.2 Crear el directorio de destino si no existe (`mkdir -p "$TARGET_SKILLS_DIR"`).

Paso 3: Enlace de Skills con Política de Advertencia
  3.1 Para cada carpeta `SKILL_PATH` en `$SUBMODULE_DIR/skills/*/`:
      a) SKILL_NAME = basename(SKILL_PATH)
      b) DEST_PATH = "$TARGET_SKILLS_DIR/$SKILL_NAME"
      c) Si DEST_PATH ya existe:
         - Si DEST_PATH es un symlink que ya apunta a SKILL_PATH:
             Estado: OMITIDO_OK (ya configurado previamente).
         - Si DEST_PATH es un directorio real o symlink a otra ubicación:
             Emitir advertencia:
             "⚠️ [WARN] El skill '$SKILL_NAME' ya existe en '$DEST_PATH'. Se omite la instalación para no sobreescribir contenido existente."
      d) Si DEST_PATH NO existe:
         - Crear symlink: `ln -s "$SKILL_PATH" "$DEST_PATH"`
         - Registrar: "✅ Skill enlazado: $SKILL_NAME -> $DEST_PATH"

Paso 4: Exclusiones Estrictas
  4.1 NO procesar ai-first-security-auditor/.
  4.2 NO intentar copiar ni procesar adapters/claude-code/agents/ salvo que el agente activo sea específicamente Claude Code.
```

---

## 4. Instrucción Directa para Agentes (Prompt Template)

Si sos un agente orquestador que necesita instalar este módulo, podés ejecutar mentalmente o en tu entorno el siguiente comando equivalente en Bash:

```bash
# Ejemplo: Instalación global para Antigravity
SUBMODULE_DIR="$(pwd)/dev-ai-toolkit"
TARGET_DIR="$HOME/.gemini/antigravity-cli/skills"

mkdir -p "$TARGET_DIR"

for skill in "$SUBMODULE_DIR"/skills/*/; do
  skill="${skill%/}"
  name="$(basename "$skill")"
  target="$TARGET_DIR/$name"

  if [ -e "$target" ] || [ -L "$target" ]; then
    current_target="$(readlink "$target" || true)"
    if [ "$current_target" = "$skill" ]; then
      echo "  [OK] $name ya está enlazado correctamente."
    else
      echo "  ⚠️ [WARN] '$name' ya existe en '$target'. Salteando para preservar archivos."
    fi
  else
    ln -s "$skill" "$target"
    echo "  ✅ [INSTALADO] $name → $target"
  fi
done
```

---

## 5. Verificación por Agente

Tras la instalación, el agente consumidor puede indicar al desarrollador cómo comprobar la carga nativa según su cliente:
- **Claude Code:** `/skills`
- **Antigravity:** Panel de Skills / Mission Control
- **Cursor / OpenCode:** Comando de inspección de herramientas y habilidades del entorno
