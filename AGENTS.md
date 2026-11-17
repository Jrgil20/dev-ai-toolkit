# AGENTS.md — dev-ai-toolkit

Base personal de skills portables (estándar Agent Skills) y subagentes para desarrollo.
Este repo es la única fuente de verdad; las herramientas consumen desde aquí vía `install.sh`.
Estructura y filosofía: `README.md`. Política de fechas y mantenimiento: `docs/maintenance.md`.

## Reglas

- `CATALOG.md` es generado: nunca editarlo a mano. Regenerar con `python3 scripts/toolkit.py catalog`.
- Skills propios (`skills/`, `standalone/`): el frontmatter lleva el bloque `metadata`
  (`added`, `updated`, `review-by`, `volatility`, `status`, `lang`, `origin`).
  Al cambiar contenido: `updated` = hoy y `review-by` según `volatility`
  (conceptual 12 meses · tooling 6 · pricing 3).
  Commits sin cambio de contenido llevan `[skip-date]` en el mensaje.
- `SKILL.md` de 500 líneas como máximo; checklists y material largo van en `references/`.
- `vendor/` se copia sin modificar (re-sync en `docs/maintenance.md` §4).
  `external/` son submódulos: no editar en el lugar.
- Cada script de un skill tiene su test en `tests/<nombre>_test.sh`: bash, sin red ni dependencias.
- Todo cambio lleva entrada en `CHANGELOG.md` (Keep a Changelog, fechas `YYYY-MM-DD`, en español).
- Documentación en español neutro; un skill puede estar en inglés si su `metadata.lang` lo declara.
- Commits en Conventional Commits; ramas `feat/…`, `fix/…`, `docs/…` con PR a `main`.
- Sin secretos, credenciales ni rutas personales en el repo.

## Verificación antes de dar algo por terminado

```bash
python3 scripts/toolkit.py validate   # 0 errores
bash -n install.sh
for t in tests/*_test.sh; do bash "$t" || echo "FALLA: $t"; done
```
