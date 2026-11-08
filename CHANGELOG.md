# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Fechas en `YYYY-MM-DD`.

## 2026-11-08 — Skill adb-device-testing

### Agregado
- `skills/adb-device-testing`: probar y medir una app web local en un Android conectado por USB. Sale de una sesión real de pruebas en un nubia Z2464N (Android 15, Chrome 137) y se validó contra ese teléfono.
  - `scripts/adb-phone.sh`: `find|devices|info|cdp|wake|up|open|await|shot|stop|down`. Reinicia el servidor adb si no aparece el dispositivo, exige pantalla encendida y sin bloqueo (nunca intenta saltar un PIN) y restaura al final `stay_on_while_plugged_in` y los túneles.
  - `scripts/cdp.mjs`: cliente mínimo de DevTools (Node 22 o superior): `targets|go|eval|shot|console|close`. Captura `console.*` y excepciones de la página del teléfono, que `logcat` no muestra.
  - `scripts/perf_listener.py` y `assets/fps-probe.html`: camino que no depende de CDP; la página mide con `requestAnimationFrame` y reporta por `adb reverse`.
  - `references/perf-probe.md` y `references/troubleshooting.md`: criterios para descartar corridas inválidas y tabla de fallas reales (pestaña pausada con la pantalla apagada, `/json/new` con 500, `ERR_UNSAFE_PORT`, HTTPS autofirmado rechazado, falso negativo de `grep -q` con `pipefail`).

## 2026-11-07 — Packs por stack: Supabase, Netlify, Vercel/React

### Agregado
- Submódulos con skills oficiales, **solo para proyectos que usan esa herramienta**:
  - `external/supabase-agent-skills` (MIT, v0.1.2, `c9be0e9`): stack `supabase`.
  - `external/netlify-context-and-tools` (MIT, `c7ef213`): stack `netlify`, 3 de 16 skills (sin `netlify-database`, que compite con Supabase).
  - `external/vercel-agent-skills` (MIT, `1a2c79d`): stack `react` y stack `vercel`.
- `install.sh --stack auto|<lista>`, `--list-stacks`, `--with-base`: con `--project --stack` instala solo los packs del proyecto (detectados por archivos de configuración y dependencias) y descarga solo los submódulos necesarios.
- `.gitmodules`: clave `toolkit-skills` (qué skill y para qué stack) y `shallow = true`.
- `github/awesome-copilot` en el catálogo como referencia (no se integra).

### Cambiado
- El validador entiende `toolkit-skills`, falla si upstream renombra un skill declarado y trata como aviso (no error) un `name` upstream que no coincide con su carpeta.
- `CATALOG.md` muestra el stack de cada skill de `external/`.

## 2026-11-07 — Cloudflare security-audit como submódulo

### Agregado
- `external/cloudflare-security-audit`: submódulo git de [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) (MIT), rama `main`, fijado en `c1c8a8c` (2026-09-14). Aporta el skill `security-audit`.
- `.github/dependabot.yml`: PR mensual cuando un submódulo de `external/` tiene cambios upstream.
- `scripts/toolkit.py external`: dice si cada submódulo está al día o cuántos commits va atrasado. `validate` ahora revisa los submódulos (spec, entrada en el catálogo, commit fijado vs. catálogo).

### Cambiado
- `install.sh`: enlaza los skills de `external/`, descarga los submódulos que falten (`--no-external` para omitirlos).
- CI clona con submódulos; el reporte mensual incluye los submódulos atrasados.
- README: instalación con `git clone --recurse-submodules` y cómo actualizar.

## 2026-11-07 — Reestructuración, fechas y comunidad

### Agregado
- Fechas de vigencia en todos los skills (`metadata.added/updated/review-by/volatility/status/lang/origin`), `CATALOG.md` generado y `docs/maintenance.md` con la política de revisión.
- `scripts/toolkit.py` (`validate`, `catalog`): valida el spec agentskills.io, fechas, archivos referenciados, `SOURCE.md` de vendor/ y el catálogo; reporta lo vencido.
- Workflow `skills-health`: valida en push/PR y abre un issue mensual con lo vencido.
- Skills propios desde la cuenta de claude.ai: `project-inception` (incompleto: falta `references/templates.md`), `deployment-cost-expert` (precios movidos a `references/pricing-snapshot.md` con fecha por fila), `executive-summary-cloud`.
- `vendor/` con copias fijadas a commit: `systematic-debugging`, `verification-before-completion`, `test-driven-development` (obra/superpowers v7.0.2, MIT), `webapp-testing` (anthropics/skills, Apache-2.0), `design-doc-mermaid` (SpillwaveSolutions, MIT; versión completa con guías y scripts).
- `catalog/community.yaml`: Superpowers, anthropics/skills, Trail of Bits (solo enlace, CC-BY-SA), design-doc-mermaid, y como candidatos supabase/agent-skills y vercel-labs/agent-skills.

### Cambiado
- `ai-first-security-auditor/` → `standalone/ai-first-security-auditor/`.
- `ai-usage-report` fusionado con `ai-usage-reporter` (claude.ai): modos manual/conversación/mixto, formato compacto alternativo, campo de validación, resumen de sesión; se elimina la llamada a la API con un ID de modelo fijo (se delega a `usage-extractor`).
- `install.sh`: instala también `vendor/` (`--no-vendor` para omitirlo), `--dry-run`, y ya **no sobreescribe** destinos existentes (antes usaba `ln -sfn`), alineado con `docs/agent-installation-spec.md`.
- `deployment-cost-expert`: corregidos datos obsoletos verificados el 2026-11-07 (Fly.io y PlanetScale sin plan gratis; Hetzner CX22→CX23 y dos subidas en 2026; planes actuales de Railway) y la regla de latencia para Latinoamérica.

## 2026-10-22
- `secure-ssh-tunnels` y `inference-security-hardening` (antes `ai-security-hardening`).

## 2026-10-15
- `docs/agent-installation-spec.md`: instalación nativa multi-agente (matriz Gentle-AI).

## 2026-10-13 / 2026-10-14
- `ai-first-security-auditor` con script de reconocimiento y patrones de remediación.

## 2026-07-01
- Versión inicial: 7 skills (code-review, test-strategy, commit-and-pr, tech-docs, clean-architecture, ddd-patterns, ai-usage-report) y 4 subagentes de Claude Code.
