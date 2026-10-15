# dev-ai-toolkit

Base personal de **skills** (portables) y **subagentes** (adaptadores por herramienta) para desarrollo de software. El repositorio es la única fuente de verdad; las herramientas (Claude Code, Claude.ai/Cowork) consumen desde aquí.

## Filosofía

1. **Skills como ciudadanos de primera clase.** Siguen el estándar Agent Skills (`SKILL.md` con frontmatter `name` + `description`), portable entre Claude Code, Claude.ai/Cowork y la API. Contienen el *conocimiento y los procedimientos* — nunca dependen de una herramienta.
2. **Subagentes como adaptadores.** Viven en `adapters/claude-code/` porque su formato (campos `tools`, `model`, `skills`) es específico de Claude Code. Su contenido (el system prompt del especialista) es markdown portable; si mañana otra herramienta soporta agentes, se agrega `adapters/<tool>/` sin tocar los skills.
3. **Determinismo.** Cada skill define proceso paso a paso, criterios de decisión en orden fijo y plantillas de salida exactas.

## Estructura

```
dev-ai-toolkit/
├── install.sh                     # symlinks → ~/.claude/ (o ./.claude con --project)
├── docs/
│   └── agent-installation-spec.md # Matriz de instalación nativa para otros agentes (Gentle-AI)
├── skills/                        # PORTABLES — estándar Agent Skills
│   ├── code-review/               # checklist + reporte fijo de review
│   ├── test-strategy/             # priorización, AAA, nomenclatura
│   ├── commit-and-pr/             # Conventional Commits + plantilla PR
│   ├── tech-docs/                 # README y ADRs con plantillas fijas
│   ├── clean-architecture/        # 4 capas + regla de dependencias
│   │   └── references/dependency-rules.md   # carga bajo demanda
│   ├── ddd-patterns/              # árbol de decisión táctico DDD
│   │   └── references/antipatterns.md       # carga bajo demanda
│   └── ai-usage-report/           # reportes estandarizados + registro ai-usage/
└── adapters/
    └── claude-code/
        └── agents/
            ├── code-reviewer.md   # read-only · precarga code-review + clean-architecture
            ├── test-runner.md     # Bash · model: haiku · resumen compacto
            ├── arch-auditor.md    # read-only · precarga clean-architecture + ddd-patterns
            └── usage-extractor.md # model: haiku · precarga ai-usage-report
```

## Diseño de ahorro de tokens

El kit aplica cuatro técnicas, cada una visible en los archivos:

1. **Divulgación progresiva (skills).** Solo la `description` (~50 palabras) está siempre en contexto. El cuerpo del `SKILL.md` se carga al activarse. Los `references/` se leen únicamente durante auditorías. Por eso los checklists largos (violaciones V1–V7, antipatrones A1–A3) viven en `references/` y no en el cuerpo.
2. **Aislamiento de contexto (subagentes).** Las tareas ruidosas — leer 30 archivos para un review, la salida cruda de una suite de tests, un transcript de 200 mensajes — ocurren dentro del subagente. La sesión principal recibe solo el reporte final. Cada agente tiene reglas explícitas de "devuelve SOLO X".
3. **Modelo económico para ejecución mecánica.** `test-runner` y `usage-extractor` declaran `model: haiku`: parsear salidas y extraer datos no requiere el modelo premium. `code-reviewer` y `arch-auditor` usan `model: inherit` porque el juicio sí importa. (Mismo patrón diseña-con-premium / ejecuta-con-económico ya usado en GitHub Actions.)
4. **Herramientas restringidas.** Los agentes de solo lectura declaran `tools: Read, Grep, Glob` — menos superficie, menos permisos, prompts de sistema más cortos.

## Integración como Submódulo para Agentes de IA

Si este repositorio se consume como submódulo o base de conocimiento para que un agente de IA instale los skills nativamente en la máquina del usuario, el agente debe consultar la especificación:

👉 **[docs/agent-installation-spec.md](docs/agent-installation-spec.md)**

Allí encontrará:
- Matriz de detección y rutas nativas para más de 14 agentes (Antigravity, Cursor, Windsurf, OpenCode, Claude Code, Gemini CLI, etc.) extraída de [Gentle-AI](https://github.com/Gentleman-Programming/gentle-ai).
- Protocolo de symlinks sólo para `skills/` (preservando `ai-first-security-auditor` como caso especial).
- Política de colisión: saltear con advertencia (`[WARN]`) sin sobreescribir archivos existentes.

## Instalación (Claude Code, Pop!_OS)

```bash
git clone <url-del-repo> ~/dev-ai-toolkit
cd ~/dev-ai-toolkit && ./install.sh        # nivel usuario
# o, dentro de un proyecto específico:
./install.sh --project
```

Los symlinks apuntan al repo: `git pull` propaga cambios sin reinstalar. Verifica con `/skills` y `/agents` dentro de Claude Code.

**En Claude.ai / Cowork:** sube el directorio del skill (o el `SKILL.md`) en Configuración → Capacidades. Los subagentes no aplican ahí; el contenido de `adapters/` puede usarse como prompt manual si hace falta.

## Uso típico

| Situación | Qué se activa |
|---|---|
| "revisa el diff del feature X" | subagente `code-reviewer` (precarga los skills) |
| "corre los tests y dime qué falla" | subagente `test-runner` (haiku, resumen compacto) |
| "¿esto va en domain o application?" | skill `clean-architecture` en la sesión principal |
| "audita la arquitectura del repo" | subagente `arch-auditor` |
| "prepara el commit y el PR" | skill `commit-and-pr` |
| "genera el reporte ai-usage de esta sesión" | skill `ai-usage-report` (+ `usage-extractor` si el transcript es largo) |

Para forzar un skill en Claude Code: `/code-review`, `/test-strategy`, etc. Para forzar un agente: mencionarlo — `@code-reviewer revisa los cambios de auth`.

## Agregar un skill nuevo

1. `mkdir skills/<nombre>` y crea `SKILL.md` con frontmatter `name` + `description`.
2. La `description` decide el auto-disparo: incluye qué hace **y** las frases del usuario que deben activarlo.
3. Cuerpo < 100 líneas; lo extenso va a `references/` con instrucción explícita de cuándo leerlo.
4. `./install.sh` de nuevo (crea el symlink faltante) y prueba con 2-3 prompts reales.

## Convenciones de frontmatter usadas

- Skills: `name`, `description` (estándar portable). Opcional en Claude Code: `disable-model-invocation: true` para skills con efectos secundarios que solo deban dispararse manualmente.
- Agentes (Claude Code): `name`, `description`, `tools` (lista separada por comas), `model` (`haiku`/`inherit`), `skills` (lista precargada completa en el contexto del agente al lanzarse).

Si algún campo no existe en tu versión de Claude Code, consulta la documentación oficial: https://code.claude.com/docs/en/features-overview
