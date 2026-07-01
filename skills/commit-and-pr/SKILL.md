---
name: commit-and-pr
description: Genera mensajes de commit en formato Conventional Commits y descripciones de PR con plantilla fija. Usar siempre que el usuario pida redactar un commit, "escribe el mensaje de commit", "prepara el PR", "describe estos cambios", o al finalizar cualquier tarea de código cuyo resultado vaya a commitearse.
---

# Commits y PRs

Redacta commits en Conventional Commits y PRs con la plantilla fija. La regla de oro: el mensaje describe el **por qué** y el **qué a nivel de comportamiento**; el diff ya muestra el cómo.

## Formato de commit

```
<tipo>(<scope>): <descripción en imperativo, ≤72 chars>

<cuerpo opcional: motivación y contexto, líneas ≤100 chars>

<footer opcional: BREAKING CHANGE:, Refs #issue>
```

Tipos permitidos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `build`.

Reglas deterministas:
- Imperativo presente: "agrega", "corrige" (no "agregado", "agregando").
- Un commit = un cambio lógico. Si el diff mezcla feat + refactor, propone dividirlo y da ambos mensajes.
- `scope` = módulo o capa afectada (`domain`, `api`, `bot`, `infra`). Omitir si el cambio es transversal.
- `BREAKING CHANGE:` en footer siempre que cambie un contrato público.

**Ejemplo 1:**
Input: agregué autenticación con JWT al endpoint de login
Output: `feat(auth): implementa autenticación JWT en login`

**Ejemplo 2:**
Input: el parser fallaba con archivos vacíos, ya lo arreglé
Output: `fix(parser): maneja archivos vacíos sin lanzar excepción`

## Plantilla de PR

```markdown
## Qué cambia
(2-4 líneas, comportamiento observable)

## Por qué
(motivación: issue, bug, decisión de diseño)

## Cómo probarlo
1. paso reproducible
2. resultado esperado

## Checklist
- [ ] Tests agregados/actualizados
- [ ] Sin secretos ni credenciales en el diff
- [ ] Documentación actualizada si aplica
```

## Proceso

1. Lee el diff completo (o `git diff --staged`) antes de escribir nada.
2. Clasifica el tipo dominante del cambio.
3. Genera commit; si hay más de un cambio lógico, genera la serie de commits propuesta.
4. Si el usuario pidió PR, genera la plantilla completa con los pasos de prueba reales del cambio.
