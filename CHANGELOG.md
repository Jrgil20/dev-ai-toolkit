# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Fechas en `YYYY-MM-DD`.

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
