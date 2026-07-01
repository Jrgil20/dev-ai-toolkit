---
name: code-review
description: Proceso determinista de revisión de código con checklist de corrección, seguridad, performance y mantenibilidad, y formato de reporte fijo. Usar siempre que el usuario pida revisar código, un PR, un diff o un módulo ("revisa este código", "code review", "¿está bien este cambio?", "dale una mirada a X"), o comparta código esperando feedback de calidad, incluso si no menciona la palabra "review".
---

# Code Review

Revisa código en pasadas ordenadas y reporta con la plantilla fija. La salida debe ser accionable: cada hallazgo cita ubicación exacta y propone la corrección, no solo señala el problema.

## Proceso (en este orden)

1. **Contexto**: identifica el propósito del cambio (mensaje de commit, descripción del PR o pregunta al usuario). No opines sin entender la intención.
2. **Corrección**: lógica, casos borde, manejo de errores, condiciones de carrera, valores nulos/vacíos.
3. **Seguridad**: inputs sin validar, inyección (SQL/command/path), secretos hardcodeados, permisos excesivos, dependencias inseguras.
4. **Performance**: consultas N+1, loops innecesarios sobre colecciones grandes, operaciones bloqueantes en rutas críticas, memoria.
5. **Mantenibilidad**: nombres, duplicación, funciones demasiado largas, acoplamiento, tests faltantes para la lógica nueva.

Si el proyecto usa Clean Architecture (hay capas domain/application/infrastructure), aplica también el skill `clean-architecture` como sexta pasada.

## Severidades

- 🔴 **Crítico**: bug que corrompe datos, vulnerabilidad explotable, crash en camino feliz. Bloquea el merge.
- 🟠 **Mayor**: bug en caso borde probable, deuda de seguridad, degradación de performance medible.
- 🟡 **Menor**: mantenibilidad, claridad, test faltante.
- 🔵 **Nit**: estilo, preferencia. Nunca bloquea.

## Formato de salida

USA SIEMPRE esta plantilla exacta:

```markdown
# Review: [alcance revisado]

## Veredicto
✅ Aprobar | ⚠️ Aprobar con cambios | ❌ Requiere cambios

## Hallazgos
| # | Sev | Ubicación | Problema | Corrección propuesta |
|---|-----|-----------|----------|----------------------|
| 1 | 🔴 | archivo.py:42 | ... | ... |

## Lo que está bien
(1-3 puntos; refuerza patrones que el autor debe mantener)

## Preguntas al autor
(solo si hay ambigüedad real; omitir la sección si no hay)
```

## Reglas

- Ubicación siempre en formato `archivo:línea` (o `archivo:línea-inicio-línea-fin`).
- Máximo 10 hallazgos, priorizados por severidad. Si hay más, agrupa los 🔵 en una sola fila "varios nits de estilo".
- El veredicto se deriva mecánicamente: cualquier 🔴 → ❌; solo 🟠/🟡 → ⚠️; solo 🔵 o nada → ✅.
- No reescribas el archivo completo salvo que el usuario lo pida; propone diffs mínimos.
