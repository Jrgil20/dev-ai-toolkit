# dev-ai-toolkit

Base personal de **skills** (portables) y **subagentes** (adaptadores por herramienta) para desarrollo de software. El repositorio es la única fuente de verdad; las herramientas (Claude Code, claude.ai, Cursor, Antigravity, OpenCode...) consumen desde aquí.

📋 **[CATALOG.md](CATALOG.md)** — inventario completo con fechas y estado de vigencia (✅ vigente · ⚠️ por vencer · ⛔ vencido · 🚧 incompleto).

## Filosofía

1. **Skills como ciudadanos de primera clase.** Siguen el estándar [Agent Skills](https://agentskills.io/specification) (`SKILL.md` con frontmatter `name` + `description`), portable entre herramientas. Contienen el *conocimiento y los procedimientos*; nunca dependen de una herramienta.
2. **Subagentes como adaptadores.** Viven en `adapters/claude-code/` porque su formato (campos `tools`, `model`, `skills`) es específico de Claude Code. Si otra herramienta soporta agentes, se agrega `adapters/<tool>/` sin tocar los skills.
3. **Determinismo.** Cada skill define proceso paso a paso, criterios de decisión en orden fijo y plantillas de salida exactas.
4. **Todo tiene fecha.** Cada skill registra cuándo entró, cuándo cambió y hasta cuándo es confiable (`review-by`). Lo vencido se detecta automáticamente. Ver [docs/maintenance.md](docs/maintenance.md).
5. **Terceros con trazabilidad.** Lo de la comunidad entra de tres formas: como **submódulo git** que sigue al upstream (`external/`), como copia fijada a un commit (`vendor/`, solo si la licencia lo permite) o como simple enlace en el catálogo. Todo con su fecha de verificación.

## Estructura

```
dev-ai-toolkit/
├── README.md · CATALOG.md (generado) · CHANGELOG.md
├── install.sh                       # symlinks → ~/.claude/ (o ./.claude con --project)
├── scripts/toolkit.py               # validate (spec + fechas + vencidos) · catalog (genera CATALOG.md)
├── .github/workflows/skills-health.yml  # valida en PR + issue mensual con lo vencido/atrasado
├── .github/dependabot.yml           # PR mensual si un submódulo de external/ tiene cambios
├── docs/
│   ├── maintenance.md               # política de fechas, revisión y re-sync de vendor/
│   └── agent-installation-spec.md   # instalación nativa en 14+ agentes (matriz Gentle-AI)
├── catalog/
│   └── community.yaml               # paquetes de la comunidad: commit, fecha verificada, instalación
├── skills/                          # PROPIOS — se instalan con install.sh
│   ├── code-review/ · test-strategy/ · commit-and-pr/ · tech-docs/
│   ├── clean-architecture/ · ddd-patterns/          (+ references/ bajo demanda)
│   ├── ai-usage-report/                              (+ references/examples-and-checklist.md)
│   ├── adb-device-testing/           # probar y medir una app web en un Android por USB (scripts/ + references/ + assets/)
│   ├── inference-security-hardening/ · secure-ssh-tunnels/
│   ├── project-inception/           # 🚧 falta references/templates.md
│   ├── deployment-cost-expert/      # precios en references/pricing-snapshot.md (fecha por fila)
│   └── executive-summary-cloud/
├── standalone/                      # PROPIOS autocontenidos — se instalan aparte
│   └── ai-first-security-auditor/   # auditoría + remediación (scripts/ + references/)
├── external/                        # TERCEROS como submódulos git (siguen la rama upstream)
│   ├── cloudflare-security-audit/   # general: security-audit (Cloudflare)
│   ├── supabase-agent-skills/       # pack stack supabase: supabase, supabase-postgres-best-practices
│   ├── netlify-context-and-tools/   # pack stack netlify: netlify-deploy, -functions, -config
│   └── vercel-agent-skills/         # pack stack react: react-best-practices, web-design-guidelines · stack vercel: deploy-to-vercel
├── vendor/                          # TERCEROS copiados sin modificar (SOURCE.md + licencia)
│   ├── systematic-debugging/ · verification-before-completion/ · test-driven-development/   # obra/superpowers (MIT)
│   ├── webapp-testing/              # anthropics/skills (Apache-2.0)
│   └── design-doc-mermaid/          # SpillwaveSolutions (MIT)
└── adapters/claude-code/agents/
    ├── code-reviewer.md             # read-only · precarga code-review + clean-architecture
    ├── test-runner.md               # Bash · model: haiku · resumen compacto
    ├── arch-auditor.md              # read-only · precarga clean-architecture + ddd-patterns
    └── usage-extractor.md           # model: haiku · precarga ai-usage-report
```

## Fechas y obsolescencia

Cada `SKILL.md` propio lleva en su frontmatter (campo `metadata` del spec):

```yaml
metadata:
  added: "2026-07-01"        # entró al repo
  updated: "2026-11-07"      # último cambio de contenido
  review-by: "2027-05-07"    # hasta cuándo se considera confiable
  volatility: "tooling"      # conceptual 12m · tooling 6m · pricing 3m
  status: "active"           # active | incomplete | deprecated
  lang: "es"
  origin: "own"
```

```bash
pip install pyyaml
python3 scripts/toolkit.py validate     # errores + vencidos + por vencer
python3 scripts/toolkit.py catalog      # regenera CATALOG.md
python3 scripts/toolkit.py external     # ¿los submódulos de external/ están al día con upstream?
```

Las copias de `vendor/` registran su origen en `SOURCE.md` (repo, commit, fecha, licencia, `review-by`); los submódulos de `external/` y los paquetes enlazados, en `catalog/community.yaml`. El día 1 de cada mes, GitHub Actions abre un issue `stale-skills` si algo venció.

## Skills de la comunidad

| Paquete | Cómo se incorpora | Por qué |
|---|---|---|
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | **Submódulo** en `external/` (se actualiza con Cloudflare) | Auditoría de seguridad multi-fase con hallazgos verificados por un agente independiente |
| [supabase/agent-skills](https://github.com/supabase/agent-skills) | **Pack por stack** (`supabase`), submódulo | Solo para proyectos con Supabase: Auth, RLS, migraciones, Edge Functions, pg_cron |
| [netlify/context-and-tools](https://github.com/netlify/context-and-tools) | **Pack por stack** (`netlify`), submódulo, 3 de 16 skills | Solo para proyectos en Netlify: deploy, functions, netlify.toml |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | **Pack por stack** (`react`, `vercel`), submódulo | Solo para proyectos React/Next.js o desplegados en Vercel |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | Solo referencia | Catálogo de ~457 skills para explorar; calidad variable |
| [obra/superpowers](https://github.com/obra/superpowers) | 3 skills en `vendor/` + plugin completo opcional | Debugging por causa raíz, TDD estricto, verificación antes de declarar "listo" |
| [anthropics/skills](https://github.com/anthropics/skills) | `webapp-testing` en `vendor/`; resto vía plugin | skill-creator, mcp-builder, pruebas web con Playwright |
| [trailofbits/skills](https://github.com/trailofbits/skills) | Solo enlace (CC-BY-SA-4.0) | insecure-defaults, supply-chain, differential-review, static-analysis |
| [SpillwaveSolutions/design-doc-mermaid](https://github.com/SpillwaveSolutions/design-doc-mermaid) | Completo en `vendor/` | Diagramas Mermaid y design docs desde código |

Comandos de instalación, commits verificados y candidatos (Supabase, Vercel) en [catalog/community.yaml](catalog/community.yaml).

## Diseño de ahorro de tokens

1. **Divulgación progresiva (skills).** Solo la `description` está siempre en contexto. El cuerpo del `SKILL.md` se carga al activarse y `references/` solo cuando hace falta. Por eso los checklists largos viven en `references/`.
2. **Aislamiento de contexto (subagentes).** Las tareas ruidosas (leer 30 archivos, la salida cruda de una suite de tests, un transcript largo) ocurren dentro del subagente; la sesión principal recibe solo el reporte final.
3. **Modelo económico para ejecución mecánica.** `test-runner` y `usage-extractor` declaran `model: haiku`; `code-reviewer` y `arch-auditor` usan `model: inherit` porque el juicio sí importa.
4. **Herramientas restringidas.** Los agentes de solo lectura declaran `tools: Read, Grep, Glob`.

## Instalación

### Claude Code (Linux / macOS)

```bash
# --recurse-submodules descarga también los skills de external/ (p. ej. el de Cloudflare)
git clone --recurse-submodules https://github.com/Jrgil20/dev-ai-toolkit ~/dev-ai-toolkit
cd ~/dev-ai-toolkit && ./install.sh          # nivel usuario: skills/ + vendor/ + external/ + agentes
./install.sh --project                       # dentro de un proyecto
./install.sh --no-vendor --no-external       # solo lo propio
./install.sh --dry-run                       # ver qué haría
```

Si ya clonaste sin `--recurse-submodules`, no pasa nada: `install.sh` descarga los submódulos que falten (o hazlo a mano con `git submodule update --init`).

### Packs por stack (Supabase, Netlify, Vercel, React)

Los skills oficiales de Supabase, Netlify y Vercel **solo sirven en proyectos que usan esas herramientas**, así que **no** se instalan con `./install.sh` a secas (cargarían descripciones inútiles en cada sesión). Se instalan por proyecto:

```bash
cd ~/proyectos/mi-saas
~/dev-ai-toolkit/install.sh --project --stack auto        # detecta el stack y enlaza solo esos packs en ./.claude/skills
~/dev-ai-toolkit/install.sh --project --stack supabase    # o elegirlos a mano: supabase, netlify, vercel, react
~/dev-ai-toolkit/install.sh --list-stacks                 # qué trae cada pack
```

| Stack | Skills | `--stack auto` lo detecta por |
|---|---|---|
| `supabase` | `supabase`, `supabase-postgres-best-practices` | `supabase/config.toml`, `@supabase/*` en package.json, `supabase` en requirements.txt/pyproject.toml |
| `netlify` | `netlify-deploy`, `netlify-functions`, `netlify-config` | `netlify.toml`, `.netlify/`, `netlify-cli`/`@netlify/*` en package.json |
| `vercel` | `deploy-to-vercel` | `vercel.json`, `.vercel/`, `vercel` en package.json |
| `react` | `vercel-react-best-practices`, `web-design-guidelines` | `react` en package.json |

Con `--project --stack`, al proyecto solo van los packs: lo general (tus skills, vendor/, Cloudflare, agentes) ya vive en `~/.claude` y así no aparece duplicado (`--with-base` lo incluye igual). Solo se descargan los submódulos que el pack necesita. Los enlaces apuntan a tu clon local, así que agrega `.claude/skills/` al `.gitignore` del proyecto si no quieres commitearlos.

**Actualizar:**

```bash
git pull --recurse-submodules                # lo propio + la versión de external/ fijada en este repo
git submodule update --remote                # traer lo último de Cloudflare (y otros upstream) ya mismo
```

Lo normal es lo primero: cada mes Dependabot abre un PR que mueve los submódulos al último commit upstream, lo revisas, lo mergeas y te llega con `git pull --recurse-submodules`. `python3 scripts/toolkit.py external` dice si algún submódulo va atrasado.

Los symlinks apuntan al repo: `git pull` propaga cambios sin reinstalar. Si ya existe un skill con el mismo nombre, se omite con `[WARN]` (nunca se sobreescribe). Verifica con `/skills` y `/agents`. Los skills de `standalone/` se instalan aparte (ver su README).

### Otros agentes (Cursor, Antigravity, OpenCode, Gemini CLI...)

Ver [docs/agent-installation-spec.md](docs/agent-installation-spec.md): matriz de rutas por agente y protocolo de symlinks.

### claude.ai

Sube la carpeta del skill en Configuración → Capacidades. Los subagentes no aplican ahí.

## Uso típico

| Situación | Qué se activa |
|---|---|
| "revisa el diff del feature X" | subagente `code-reviewer` (precarga los skills) |
| "corre los tests y dime qué falla" | subagente `test-runner` |
| "¿esto va en domain o application?" | `clean-architecture` |
| "audita la arquitectura del repo" | subagente `arch-auditor` |
| "prepara el commit y el PR" | `commit-and-pr` |
| "genera el reporte ai-usage de esta sesión" | `ai-usage-report` (+ `usage-extractor` si el transcript es largo) |
| "tengo una idea para una app" | `project-inception` |
| "¿dónde despliego y cuánto cuesta?" | `deployment-cost-expert` (verifica precios con fecha) |
| "resume este informe del laboratorio de nube" | `executive-summary-cloud` |
| "este test falla y no sé por qué" | `systematic-debugging` → `test-driven-development` → `verification-before-completion` |
| "prueba la app local en el navegador" | `webapp-testing` |
| "haz el diagrama de secuencia de este flujo" | `design-doc-mermaid` |
| "prueba en el teléfono", "mide los fps en el celular" | `adb-device-testing` |
| "audita la seguridad del servidor de inferencia/VLM" | `inference-security-hardening` |
| "configura un túnel SSH para la GPU/cámara" | `secure-ssh-tunnels` |
| "audita la seguridad de este MVP hecho con IA" | `standalone/ai-first-security-auditor` |
| "haz una auditoría de seguridad completa de este repo" / "¿este endpoint es explotable?" | `security-audit` (Cloudflare, `external/`) |
| "la política RLS no deja leer a este tenant" (proyecto con Supabase) | `supabase` (pack `supabase`) |
| "agrega una función serverless y redirecciones" (proyecto en Netlify) | `netlify-functions`, `netlify-config` (pack `netlify`) |
| "este componente re-renderiza demasiado" (proyecto React) | `vercel-react-best-practices` (pack `react`) |

Para forzar un skill en Claude Code: `/code-review`, `/test-strategy`, etc. Para forzar un agente: `@code-reviewer revisa los cambios de auth`.

## Agregar un skill propio

1. `mkdir skills/<nombre>` y crea `SKILL.md` con `name` (igual a la carpeta), `description` y el bloque `metadata` de arriba.
2. La `description` decide el auto-disparo: incluye qué hace **y** las frases del usuario que deben activarlo.
3. Cuerpo < 100 líneas; lo extenso va a `references/` con instrucción explícita de cuándo leerlo. Datos que caducan (precios, versiones) van en un archivo de referencia con fecha por fila.
4. `python3 scripts/toolkit.py validate && python3 scripts/toolkit.py catalog`.
5. `./install.sh` (crea el symlink faltante) y prueba con 2-3 prompts reales.

## Convenciones de frontmatter

- Skills: `name`, `description` (estándar), `metadata` (fechas, todas las claves como strings). Opcionales del spec: `license`, `compatibility`, `allowed-tools`. En Claude Code: `disable-model-invocation: true` para skills con efectos secundarios que solo deban dispararse a mano.
- Agentes (Claude Code): `name`, `description`, `tools`, `model` (`haiku`/`inherit`), `skills` (precargados). Sus fechas salen del historial git.

Documentación oficial: https://code.claude.com/docs/en/features-overview · https://agentskills.io/specification
