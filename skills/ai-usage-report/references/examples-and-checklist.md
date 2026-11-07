# AI Usage Report — ejemplos y checklist

> Origen: ejemplos y checklist tomados del skill `ai-usage-reporter` (cuenta claude.ai) al fusionarlo, 2026-11-07.

## Checklist antes de entregar

- [ ] Fecha en formato `YYYY-MM-DD`
- [ ] Resumen de tarea en ≤ 10 palabras (formato B) o título descriptivo (formato A)
- [ ] Herramienta y modelo especificados (o "No especificado")
- [ ] Al menos 1 prompt representativo
- [ ] Salida descrita con nombres de archivos/funciones concretos cuando aplique
- [ ] Modificaciones manuales: específicas o "Ninguna" — nunca vacío
- [ ] Validación descrita o "No especificada" — nunca vacío
- [ ] Si la entrada fue una conversación: bloque "Resumen de la sesión" agregado
- [ ] `ai-usage/INDEX.md` actualizado (formato A)

## Errores comunes

- Inventar prompts o salidas que no fueron mencionados.
- Resúmenes genéricos ("se usó IA").
- Confundir "salida tomada" con "todo lo que generó la IA": solo lo que el equipo adoptó.
- Omitir el resumen de sesión cuando el input era una conversación completa.

## Ejemplo — Formato B, entrada manual

```markdown
### 2025-07-14 — Componente React para tabla de datos paginada

- **Herramienta:** Claude
- **Modelo / versión:** No especificado
- **Autor humano responsable:** @dev-maria
- **Prompt(s) representativo(s):**
  - "Crea un componente React con TypeScript para mostrar una tabla paginada con sorting"
  - "Agrega un filtro de búsqueda por columna"
- **Salida tomada de la IA:** `DataTable.tsx` con hooks de sorting/paginación y tipos TypeScript
- **Modificaciones manuales del equipo:** Tamaño de página default de 10 a 25; prop `data` renombrada a `rows`
- **Validación realizada:** Tests unitarios con Vitest (4/4); revisión manual del equipo frontend
```

## Ejemplo — Formato A, desde conversación (fragmento final)

```markdown
## Modificaciones humanas
El secret de JWT se movió a variables de entorno (la IA lo dejó hardcodeado en el ejemplo); expiración ajustada a 1h.

## Validación realizada
Tests de integración con Supertest; revisión de seguridad del tech lead.

## Resumen de la sesión
- **Duración estimada**: 18 turnos / ~25 minutos
- **Decisiones clave del humano**: separar access token (1h) de refresh token (7d); no usar localStorage
- **Patrón de uso**: iterativo — refinó con preguntas de seguridad específicas
```
