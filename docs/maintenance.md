# Mantenimiento: fechas, vigencia y obsolescencia

> **Última revisión:** 2026-11-07

Los skills envejecen a ritmos distintos: un principio de Clean Architecture dura años, un precio de hosting dura semanas. Este repo registra **cuándo** se escribió o verificó cada cosa y **hasta cuándo** se considera confiable, para detectar lo obsoleto antes de que cause un error.

## 1. Dónde vive cada fecha

| Qué | Dónde | Campos |
|---|---|---|
| Skill propio (`skills/`, `standalone/`) | Frontmatter `metadata` del `SKILL.md` (campo estándar del spec [agentskills.io](https://agentskills.io/specification)) | `added`, `updated`, `review-by`, `volatility`, `status`, `lang`, `origin` |
| Skill de terceros (`vendor/`) | `vendor/<skill>/SOURCE.md` (el `SKILL.md` upstream no se toca) | `upstream-commit`, `upstream-commit-date`, `synced`, `review-by`, `license`, `modified` |
| Skill de terceros por submódulo (`external/`) | Entrada de `catalog/community.yaml` con `submodule: external/<x>`; el commit fijado lo guarda git | `upstream-commit`, `upstream-commit-date`, `verified`, `review-by` |
| Paquete de la comunidad (solo enlace) | `catalog/community.yaml` | `upstream-commit`, `upstream-commit-date`, `verified`, `review-by` |
| Subagentes (`adapters/`) | Derivadas del historial git (no se agregan campos extra al formato de Claude Code) | primer/último commit + 6 meses |
| Datos volátiles dentro de un skill (precios, versiones) | El propio archivo de referencia, por fila | columna "Verificado" (ver `deployment-cost-expert/references/pricing-snapshot.md`) |

Todas las fechas van en formato `YYYY-MM-DD` **entre comillas** (el spec exige que `metadata` sea un mapa de strings).

## 2. Significado de los campos

- `added`: fecha en que el skill entró a este repo.
- `updated`: última modificación **de contenido** (no de formato ni de metadata).
- `review-by`: fecha límite para releerlo y confirmar que sigue siendo correcto. Al revisarlo, aunque no cambie nada, se mueve `review-by` hacia adelante.
- `volatility` → ventana máxima de `review-by` desde `updated`:
  - `conceptual` (principios, procesos, plantillas): **12 meses**
  - `tooling` (CLIs, versiones, nombres de modelos, formatos de herramientas): **6 meses**
  - `pricing` (precios, planes, cuotas gratis): **3 meses**
  - vendor/ y comunidad: **3 meses** (los upstream se mueven rápido)
- `status`: `active` · `incomplete` (le falta algo para funcionar) · `deprecated` (se conserva por historial; no usar).
- `origin`: `own`, o de dónde vino (p. ej. skill de la cuenta de claude.ai).

## 3. Rutina

```bash
python3 scripts/toolkit.py validate          # errores de estructura + vencidos + por vencer
python3 scripts/toolkit.py catalog           # regenera CATALOG.md
```

Además, el workflow `skills-health` valida cada push/PR y **el día 1 de cada mes** abre o comenta un issue `stale-skills` con lo vencido.

### Al editar un skill propio
1. Cambia el contenido.
2. Actualiza `metadata.updated` a hoy y recalcula `review-by` según `volatility`.
3. `python3 scripts/toolkit.py catalog` y commit.

El validador avisa si el último commit que tocó la carpeta es posterior a `updated`. Para commits que **no** cambian contenido (mover archivos, solo metadata, formato), incluye `[skip-date]` en el mensaje del commit y el validador los ignora.

### Al revisar algo vencido
- Sigue vigente → solo mueve `review-by` (y `verified` en el catálogo).
- Cambió → actualiza contenido, `updated` y `review-by`.
- Ya no sirve → `status: "deprecated"` y explica el reemplazo en el cuerpo; elimínalo en una limpieza posterior.

## 4. Re-sincronizar `vendor/`

```bash
# ejemplo para un skill de obra/superpowers
git clone --depth 1 https://github.com/obra/superpowers /tmp/up
diff -ru vendor/systematic-debugging /tmp/up/skills/systematic-debugging \
  -x SOURCE.md -x LICENSE-UPSTREAM          # revisa qué cambió
rsync -a --delete --exclude SOURCE.md --exclude LICENSE-UPSTREAM \
  /tmp/up/skills/systematic-debugging/ vendor/systematic-debugging/
```

Luego en `SOURCE.md`: `upstream-commit`, `upstream-commit-date`, `upstream-version`, `synced` (hoy) y `review-by` (hoy + 3 meses). Si modificas una copia, pon `modified: "yes"` y describe el cambio (requisito de Apache-2.0 y buena práctica en MIT).

Reglas de licencia para vendorizar:
- MIT / Apache-2.0: permitido, con `SOURCE.md` + texto de licencia upstream.
- CC-BY-SA, GPL u otras share-alike/copyleft: **no** se copian; solo se enlazan en `catalog/community.yaml`.
- Sin licencia declarada: no se copian.

## 4b. Submódulos de `external/`

Para upstreams que se mantienen activamente y cuya licencia permite redistribuir, se prefiere un submódulo a una copia: se actualiza con un comando y no hay que diffear a mano.

**Actualizar** (Dependabot lo propone cada mes con un PR; a mano):

```bash
python3 scripts/toolkit.py external                         # ¿va atrasado?
git submodule update --remote external/cloudflare-security-audit
git -C external/cloudflare-security-audit log --oneline -10 # revisa qué cambió
```

Luego en `catalog/community.yaml` actualiza `upstream-commit`, `upstream-commit-date`, `verified` (hoy) y `review-by` (hoy + 3 meses). El validador avisa si el commit fijado no coincide con el del catálogo, así que en el PR de Dependabot verás ese aviso hasta que lo hagas.

**Agregar uno nuevo:**

```bash
git submodule add -b main https://github.com/<owner>/<repo> external/<nombre>
```

y su entrada en `catalog/community.yaml` con `submodule: external/<nombre>`. `install.sh` enlaza cada `external/<x>/skills/*/SKILL.md` (o `external/<x>/SKILL.md`) automáticamente.

Advertencia: un submódulo trae lo que publique el upstream. Revisa el diff del PR de Dependabot antes de mergear; un skill puede incluir scripts que el agente ejecutará.

## 5. Agregar un paquete de la comunidad al catálogo

Agrega una entrada a `catalog/community.yaml` con el commit que revisaste, la fecha (`verified`) y `review-by` = verified + 3 meses. Lista en `recommended` solo lo que realmente usarías y por qué. Corre `validate` y `catalog`.

## 6. Pendientes conocidos

- `skills/project-inception`: falta `references/templates.md` (la copia de claude.ai solo traía el `SKILL.md`). Hasta agregarlo queda `status: "incomplete"`.
- El repo no declara una licencia propia (`LICENSE`). Las copias de `vendor/` conservan sus licencias, pero el contenido propio queda "todos los derechos reservados" hasta que elijas una.
