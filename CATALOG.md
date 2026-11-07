# Catálogo de dev-ai-toolkit

> Generado por `python3 scripts/toolkit.py catalog` el **2026-11-07**. No editar a mano: la fuente de verdad es el frontmatter de cada skill, `vendor/*/SOURCE.md`, `catalog/community.yaml`, `.gitmodules` y el historial git.
>
> **Estado**: ✅ vigente · ⚠️ vence en ≤30 días · ⛔ vencido (revisar/actualizar) · 🚧 incompleto · 🗄️ obsoleto. Ventanas de revisión: conceptual 12 meses, tooling 6, pricing 3, vendor/comunidad 3.

## Skills propios (`skills/`)

| Skill | Idioma | Volatilidad | Agregado | Actualizado | Revisar antes de | Estado |
|---|---|---|---|---|---|---|
| [`ai-usage-report`](skills/ai-usage-report/SKILL.md) | es | tooling | 2026-07-01 | 2026-11-07 | 2027-05-07 | ✅ vigente |
| [`clean-architecture`](skills/clean-architecture/SKILL.md) | es | conceptual | 2026-07-01 | 2026-07-01 | 2027-07-01 | ✅ vigente |
| [`code-review`](skills/code-review/SKILL.md) | es | conceptual | 2026-07-01 | 2026-07-01 | 2027-07-01 | ✅ vigente |
| [`commit-and-pr`](skills/commit-and-pr/SKILL.md) | es | conceptual | 2026-07-01 | 2026-07-01 | 2027-07-01 | ✅ vigente |
| [`ddd-patterns`](skills/ddd-patterns/SKILL.md) | es | conceptual | 2026-07-01 | 2026-07-01 | 2027-07-01 | ✅ vigente |
| [`deployment-cost-expert`](skills/deployment-cost-expert/SKILL.md) | es | pricing | 2026-11-07 | 2026-11-07 | 2027-02-07 | ✅ vigente |
| [`executive-summary-cloud`](skills/executive-summary-cloud/SKILL.md) | es | conceptual | 2026-11-07 | 2026-11-07 | 2027-11-07 | ✅ vigente |
| [`inference-security-hardening`](skills/inference-security-hardening/SKILL.md) | en | tooling | 2026-10-22 | 2026-10-22 | 2027-04-22 | ✅ vigente |
| [`project-inception`](skills/project-inception/SKILL.md) | es | conceptual | 2026-11-07 | 2026-11-07 | 2027-11-07 | 🚧 incompleto |
| [`secure-ssh-tunnels`](skills/secure-ssh-tunnels/SKILL.md) | en | tooling | 2026-10-22 | 2026-10-22 | 2027-04-22 | ✅ vigente |
| [`tech-docs`](skills/tech-docs/SKILL.md) | es | conceptual | 2026-07-01 | 2026-07-01 | 2027-07-01 | ✅ vigente |
| [`test-strategy`](skills/test-strategy/SKILL.md) | es | conceptual | 2026-07-01 | 2026-07-01 | 2027-07-01 | ✅ vigente |

## Skills autocontenidos (`standalone/`)

Se instalan aparte (submódulo o copia manual); `install.sh` no los enlaza.

| Skill | Idioma | Volatilidad | Agregado | Actualizado | Revisar antes de | Estado |
|---|---|---|---|---|---|---|
| [`ai-first-security-auditor`](standalone/ai-first-security-auditor/SKILL.md) | en | tooling | 2026-10-13 | 2026-10-14 | 2027-04-14 | ✅ vigente |

## Skills de terceros copiados (`vendor/`)

Copias sin modificar, fijadas a un commit. Ver `SOURCE.md` en cada carpeta.

| Skill | Upstream | Commit | Fecha del commit | Sincronizado | Licencia | Revisar antes de | Estado |
|---|---|---|---|---|---|---|---|
| [`design-doc-mermaid`](vendor/design-doc-mermaid/SKILL.md) | [SpillwaveSolutions/design-doc-mermaid](https://github.com/SpillwaveSolutions/design-doc-mermaid) | `c36d835` | 2026-08-24 | 2026-11-07 | MIT (declarada en README; upstream no incluye archivo LICENSE) | 2027-02-07 | ✅ vigente |
| [`systematic-debugging`](vendor/systematic-debugging/SKILL.md) | [obra/superpowers](https://github.com/obra/superpowers) | `22f0b46` | 2026-11-03 | 2026-11-07 | MIT | 2027-02-07 | ✅ vigente |
| [`test-driven-development`](vendor/test-driven-development/SKILL.md) | [obra/superpowers](https://github.com/obra/superpowers) | `22f0b46` | 2026-11-03 | 2026-11-07 | MIT | 2027-02-07 | ✅ vigente |
| [`verification-before-completion`](vendor/verification-before-completion/SKILL.md) | [obra/superpowers](https://github.com/obra/superpowers) | `22f0b46` | 2026-11-03 | 2026-11-07 | MIT | 2027-02-07 | ✅ vigente |
| [`webapp-testing`](vendor/webapp-testing/SKILL.md) | [anthropics/skills](https://github.com/anthropics/skills) | `2c5958e` | 2026-11-06 | 2026-11-07 | Apache-2.0 | 2027-02-07 | ✅ vigente |

## Skills de terceros por submódulo (`external/`)

Siguen la rama upstream: `git submodule update --remote` (o el PR mensual de Dependabot) los trae al día. Clona con `--recurse-submodules`.

| Skill | Upstream | Rama | Commit fijado | Fecha del commit | Licencia | Revisar antes de | Estado |
|---|---|---|---|---|---|---|---|
| [`security-audit`](external/cloudflare-security-audit/skills/security-audit/SKILL.md) | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | main | `c1c8a8c` | 2026-09-14 | MIT | 2027-02-07 | ✅ vigente |

## Paquetes de la comunidad (`catalog/community.yaml`)

| Paquete | Versión / commit | Fecha upstream | Verificado | Licencia | Recomendados | Integración | Revisar antes de | Estado |
|---|---|---|---|---|---|---|---|---|
| [anthropics/skills](https://github.com/anthropics/skills) | `2c5958e` | 2026-11-06 | 2026-11-07 | Apache-2.0 (revisar LICENSE.txt de cada skill) | skill-creator, mcp-builder, webapp-testing, frontend-design | vendor/: webapp-testing | 2027-02-07 | ✅ vigente |
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | `c1c8a8c` | 2026-09-14 | 2026-11-07 | MIT | security-audit | submódulo `external/cloudflare-security-audit` | 2027-02-07 | ✅ vigente |
| [SpillwaveSolutions/design-doc-mermaid](https://github.com/SpillwaveSolutions/design-doc-mermaid) | `c36d835` | 2026-08-24 | 2026-11-07 | MIT (declarada en README, sin archivo LICENSE) | design-doc-mermaid | vendor/: design-doc-mermaid | 2027-02-07 | ✅ vigente |
| [obra/superpowers](https://github.com/obra/superpowers) | 7.0.2 · `22f0b46` | 2026-11-03 | 2026-11-07 | MIT | systematic-debugging, verification-before-completion, test-driven-development, brainstorming + writing-plans + executing-plans | vendor/: systematic-debugging, verification-before-completion, test-driven-development | 2027-02-07 | ✅ vigente |
| [supabase/agent-skills](https://github.com/supabase/agent-skills) | `c9be0e9` | 2026-10-02 | 2026-11-07 | MIT | supabase-postgres-best-practices | solo enlace | 2027-02-07 | ✅ vigente |
| [trailofbits/skills](https://github.com/trailofbits/skills) | `e4dd0bb` | 2026-11-06 | 2026-11-07 | CC-BY-SA-4.0 | insecure-defaults, supply-chain-risk-auditor, differential-review, static-analysis, sharp-edges | solo enlace | 2027-02-07 | ✅ vigente |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | `1a2c79d` | 2026-10-27 | 2026-11-07 | MIT | react-best-practices, web-design-guidelines | solo enlace | 2027-02-07 | ✅ vigente |

## Subagentes de Claude Code (`adapters/claude-code/agents/`)

Fechas derivadas del historial git; revisión a los 6 meses del último cambio (dependen de alias de modelo y campos de Claude Code).

| Agente | Modelo | Skills precargados | Agregado | Actualizado | Revisar antes de | Estado |
|---|---|---|---|---|---|---|
| [`arch-auditor`](adapters/claude-code/agents/arch-auditor.md) | inherit | clean-architecture, ddd-patterns | 2026-07-01 | 2026-07-01 | 2027-01-01 | ✅ vigente |
| [`code-reviewer`](adapters/claude-code/agents/code-reviewer.md) | inherit | code-review, clean-architecture | 2026-07-01 | 2026-07-01 | 2027-01-01 | ✅ vigente |
| [`test-runner`](adapters/claude-code/agents/test-runner.md) | haiku | — | 2026-07-01 | 2026-07-01 | 2027-01-01 | ✅ vigente |
| [`usage-extractor`](adapters/claude-code/agents/usage-extractor.md) | haiku | ai-usage-report | 2026-07-01 | 2026-07-01 | 2027-01-01 | ✅ vigente |
