---
name: ai-usage-report
description: Genera reportes estandarizados de uso de IA (AI Usage Report) en Markdown y los registra en el directorio ai-usage/ del proyecto. Usar siempre que el usuario mencione "ai-usage", "reporte de IA", "registro de uso de IA", "AI usage report", "documenta el uso de Claude/Copilot/Gemini/GPT", "registra esta sesión", comparta una conversación pidiendo resumen de uso, o al cerrar una sesión de trabajo asistida por IA cuyo uso deba quedar trazado. Acepta datos manuales, una conversación completa o una mezcla de ambos.
metadata:
  added: "2026-07-01"
  updated: "2026-11-07"
  review-by: "2027-05-07"
  volatility: "tooling"
  status: "active"
  lang: "es"
  origin: "own (fusionado con ai-usage-reporter de claude.ai, 2026-11-07)"
---

# AI Usage Report

Genera reportes de uso de herramientas de IA con uno de los dos formatos fijos de abajo y mantiene el registro del proyecto en `ai-usage/`. Ejemplos completos y checklist de entrega: `references/examples-and-checklist.md` (leer solo si hay dudas de formato).

## Paso 1 — Identificar el modo de entrada

| Modo | Qué recibes | Qué haces |
|---|---|---|
| Manual | Datos sueltos (herramienta, tarea, prompts...) | Pregunta solo los campos obligatorios que falten |
| Conversación | Transcript completo pegado o en archivo | Extrae los campos (Paso 2) |
| Mixto | Datos parciales + fragmentos | Combina: lo dicho por el usuario prevalece sobre lo extraído |

Campos obligatorios: herramienta, modelo (o "No especificado"), tarea. Si falta alguno y no se puede extraer, pregunta — no inventes valores.

## Paso 2 — Extraer de una conversación

- Mensajes del usuario → prompts representativos (los que mejor capturan la intención, máx. 3).
- Mensajes del asistente → salida generada; **salida tomada** = solo lo que el humano adoptó.
- Indicadores de edición manual: "lo cambié a", "ajusté", "modifiqué", "renombré".
- Indicadores de validación: "lo probé", "pasó los tests", "revisé", "lint".

Si el transcript supera ~20 turnos o ~3000 palabras, delega la extracción al subagente `usage-extractor` (modelo económico) y trabaja solo con su resumen estructurado. No codifiques IDs de modelo en llamadas a API: cambian y quedan obsoletos.

## Paso 3 — Formato A: reporte de sesión (por defecto)

Archivo: `ai-usage/YYYY-MM-DD-<slug-de-la-tarea>.md`

```markdown
# AI Usage Report: [tarea]

- **Fecha**: YYYY-MM-DD
- **Autor humano responsable**: @Jrgil20
- **Herramienta(s)**: [Claude web | Claude Code | GitHub Copilot | Cursor | ...]
- **Modelo(s)**: [identificador exacto si se conoce, si no "No especificado"]
- **Proyecto/Contexto**: [repo o asignación]

## Objetivo de la sesión
(1-2 líneas: qué se quería lograr)

## Uso realizado
| # | Prompt/Instrucción (resumen) | Salida generada (resumen) | Aceptado tal cual |
|---|------------------------------|---------------------------|-------------------|

## Modificaciones humanas
(qué se corrigió, reescribió o descartó y por qué; si nada: "Ninguna")

## Validación realizada
(tests, lint, revisión humana...; si nada: "No especificada")

## Artefactos resultantes
(archivos/commits producidos, con rutas)

## Evaluación
- **Ahorro estimado**: [tiempo o esfuerzo]
- **Limitaciones observadas**: [errores del modelo, iteraciones necesarias]
```

Si la entrada fue una conversación completa, agrega al final:

```markdown
## Resumen de la sesión
- **Duración estimada**: <N turnos / ~N minutos>
- **Decisiones clave del humano**: <2-3 decisiones>
- **Patrón de uso**: <iterativo | directivo | explorador | mixto>
```

## Paso 3 (alternativo) — Formato B: entrada compacta

Úsalo cuando el usuario pida "una entrada" para anexar a un `AI_USAGE.md` único (p. ej. entregas de cursos):

```markdown
### YYYY-MM-DD — <resumen de la tarea, máx. 10 palabras>

- **Herramienta:** ...
- **Modelo / versión:** ... | "No especificado"
- **Autor humano responsable:** ...
- **Prompt(s) representativo(s):**
  - "..."
- **Salida tomada de la IA:** <archivos/funciones concretos>
- **Modificaciones manuales del equipo:** ... | "Ninguna"
- **Validación realizada:** ... | "No especificada"
```

## Paso 4 — Registro del proyecto

Mantén `ai-usage/INDEX.md` con una fila por reporte y actualízalo en la misma operación:

```markdown
| Fecha | Tarea | Herramienta | Reporte |
|-------|-------|-------------|---------|
| 2026-07-01 | Refactor parser | Claude Code | [link](./2026-07-01-refactor-parser.md) |
```

## Reglas

- Fechas siempre `YYYY-MM-DD`; nunca "hoy" o "ayer". Sin fecha dada → la de hoy.
- Ningún campo vacío: usar "No especificado" o "Ninguna".
- Nunca incluyas secretos, tokens ni datos personales de terceros; redacta con `[REDACTADO]`.
- Registro fiel: las salidas rechazadas también se registran (columna "Aceptado tal cual" = No).
- Un reporte por sesión; sesiones distintas el mismo día llevan slug distinto.
