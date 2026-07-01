---
name: ai-usage-report
description: Genera reportes estandarizados de uso de IA (AI Usage Report) en Markdown y los registra en el directorio ai-usage/ del proyecto. Usar siempre que el usuario mencione "ai-usage", "reporte de IA", "documenta el uso de Claude/Copilot/Gemini", "registra esta sesión", comparta una conversación pidiendo resumen de uso, o al cerrar una sesión de trabajo asistida por IA cuyo uso deba quedar trazado.
---

# AI Usage Report

Genera reportes de uso de herramientas de IA con el formato estándar de abajo y mantiene el registro del proyecto en `ai-usage/`.

## Entradas aceptadas

1. **Datos manuales**: el usuario describe qué herramienta usó y para qué.
2. **Conversación/sesión completa**: extraer los datos del transcript. Si el transcript es muy largo, delega la extracción al subagente `usage-extractor` (si está disponible) y trabaja solo con su resumen estructurado.

Si falta alguno de los campos obligatorios (herramienta, modelo, tarea), pregunta antes de generar — no inventes valores.

## Formato del reporte

Archivo: `ai-usage/YYYY-MM-DD-<slug-de-la-tarea>.md`

```markdown
# AI Usage Report: [tarea]

- **Fecha**: YYYY-MM-DD
- **Autor**: @Jrgil20
- **Herramienta(s)**: [Claude web | Claude Code | GitHub Copilot | ...]
- **Modelo(s)**: [identificador exacto si se conoce]
- **Proyecto/Contexto**: [repo o asignación]

## Objetivo de la sesión
(1-2 líneas: qué se quería lograr)

## Uso realizado
| # | Prompt/Instrucción (resumen) | Salida generada (resumen) | Aceptado tal cual |
|---|------------------------------|---------------------------|-------------------|

## Modificaciones humanas
(qué se corrigió, reescribió o descartó de lo generado, y por qué)

## Artefactos resultantes
(archivos/commits producidos, con rutas)

## Evaluación
- **Ahorro estimado**: [tiempo o esfuerzo]
- **Limitaciones observadas**: [errores del modelo, iteraciones necesarias]
```

## Registro del proyecto

Mantén `ai-usage/INDEX.md` con una fila por reporte:

```markdown
| Fecha | Tarea | Herramienta | Reporte |
|-------|-------|-------------|---------|
| 2026-07-01 | Refactor parser | Claude Code | [link](./2026-07-01-refactor-parser.md) |
```

## Reglas

- Nunca incluyas secretos, tokens ni datos personales de terceros en el reporte; redacta con `[REDACTADO]`.
- Resúmenes fieles: si una salida fue rechazada, se registra igual — el registro documenta el uso real, no solo los aceptados.
- Un reporte por sesión de trabajo; sesiones distintas el mismo día llevan slug distinto.
- Tras crear el reporte, actualiza `INDEX.md` en la misma operación.
