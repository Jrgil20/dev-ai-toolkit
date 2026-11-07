---
name: project-inception
description: Transforma una idea cruda de proyecto en documentación fundacional completa antes de escribir código - visión, alcance (in/out), requisitos funcionales RF-XXX con prioridad MoSCoW, requisitos no funcionales con métricas, features con trazabilidad y stack sugerido. Usa este skill SIEMPRE que el usuario tenga una idea de app, sistema, bot o producto sin documentación previa y diga cosas como "tengo una idea", "quiero arrancar/empezar un proyecto", "ayúdame a sacar los requisitos/requerimientos", "definir el alcance", "darle forma a mi idea", "qué debería tener mi app", "levantamiento de requisitos", "documentación inicial" o "definir el MVP" - incluso si solo describe informalmente lo que quiere construir sin pedir documentos explícitamente. También aplica en inglés ("I have an idea for...", "help me define requirements/scope").
metadata:
  added: "2026-11-07"
  updated: "2026-11-07"
  review-by: "2027-11-07"
  volatility: "conceptual"
  status: "incomplete"
  lang: "es"
  origin: "claude.ai account skill (fecha de creación original desconocida)"
---

# Project Inception

## Propósito

Acompañar el momento cero de un proyecto: convertir una idea cruda en documentación fundacional verificable, **sin escribir código**. El resultado son 6 documentos Markdown que funcionan como contrato de entendimiento antes de diseñar arquitectura o implementar. Este skill cubre la fase de concepción; el diseño técnico detallado viene después y no es parte de este alcance.

## Principios

1. **Nada inventado.** Cada requisito debe trazarse a algo que el usuario dijo o confirmó explícitamente. Si falta información, se pregunta o se registra como supuesto explícito — nunca se rellena en silencio. La documentación fundacional pierde todo su valor si contiene deseos del asistente en vez de necesidades del usuario.
2. **Adaptativo.** El esfuerzo de elicitación depende de cuánto contexto dio el usuario. No sometas a interrogatorio a quien ya escribió dos párrafos detallados; no generes documentos a quien escribió una sola frase.
3. **Determinista.** Mismas plantillas, mismo orden de secciones, mismas convenciones de IDs, siempre. Dos proyectos distintos documentados con este skill deben verse estructuralmente idénticos.
4. **Proporcional.** El volumen de requisitos refleja el tamaño real del proyecto. Un MVP personal razonable puede tener 8-15 RF; inflar la lista con requisitos genéricos es un defecto, no un logro.

## Flujo de trabajo

Ejecuta las fases en este orden estricto. Solo la Fase 1 puede omitirse (cuando no hay brechas).

### Fase 0 — Análisis de brechas (interno, siempre)

Lee todo lo que el usuario proporcionó y clasifica cada dimensión como **CLARO**, **PARCIAL** o **AUSENTE**. Este análisis es interno: no muestres la tabla al usuario, pero úsala para decidir qué preguntar.

| # | Dimensión | Pregunta que responde |
|---|-----------|-----------------------|
| 1 | Problema | ¿Qué problema resuelve y para quién? |
| 2 | Usuarios/actores | ¿Quién lo usa? ¿Qué roles existen? |
| 3 | Alcance IN | ¿Qué hace la primera versión? |
| 4 | Alcance OUT | ¿Qué explícitamente NO hará (aún)? |
| 5 | Flujos principales | ¿Cuáles son los 2-4 recorridos core del usuario? |
| 6 | Datos clave | ¿Qué entidades/información maneja el sistema? |
| 7 | Restricciones | Plataforma, plazos, presupuesto, integraciones obligadas, equipo |
| 8 | Criterios de éxito | ¿Cómo se sabrá que el proyecto funcionó? |

### Fase 1 — Elicitación adaptativa

Según el resultado de la Fase 0:

- **Mayoría AUSENTE** (idea de una frase): entrevista guiada. Recorre las dimensiones en orden 1→8, agrupando preguntas por tema, **máximo 3-4 preguntas por turno**. Cuando la respuesta sea enumerable, ofrece opciones concretas ("¿web, móvil o ambos?") — elegir es más fácil que redactar desde cero.
- **Mezcla PARCIAL/CLARO**: primero refleja en 2-3 líneas lo que ya entendiste (para que el usuario no repita), luego pregunta **solo** las brechas.
- **Todo CLARO** (poco común): salta directo a la Fase 2.

**Regla de corte:** cuando las dimensiones 1-5 estén CLARAS y las 6-8 al menos PARCIALES, pasa a la Fase 2. Perseguir la elicitación perfecta fatiga al usuario; los documentos se pueden iterar después. Lo que quede sin resolver se registra como supuesto explícito.

### Fase 2 — Checkpoint de validación (obligatorio)

Antes de generar cualquier documento, presenta un resumen compacto (no los documentos completos):

- Problema y usuarios en 2-3 líneas
- Lista IN / OUT del alcance
- Features tentativas con prioridad MoSCoW tentativa
- Restricciones detectadas y supuestos que estás asumiendo

Pide confirmación o correcciones. Este checkpoint existe porque corregir aquí cuesta un mensaje; corregir después de generar 6 documentos cuesta regenerarlos todos. **No generes documentos sin confirmación explícita del usuario.**

### Fase 3 — Generación de documentos

Con el entendimiento validado, **lee `references/templates.md`** y genera los 6 documentos siguiendo exactamente esas plantillas (mismos títulos, mismo orden de secciones):

| Archivo | Contenido |
|---------|-----------|
| `docs/00-vision.md` | Problema, propuesta de valor, objetivos, actores, criterios de éxito, supuestos |
| `docs/01-alcance.md` | In-scope del MVP, out-of-scope explícito con motivo, ideas futuras |
| `docs/02-requisitos-funcionales.md` | RF-001... con actor, prioridad MoSCoW, criterios de aceptación, feature asociada |
| `docs/03-requisitos-no-funcionales.md` | RNF-001... por categoría, con métrica verificable |
| `docs/04-features.md` | Features F-XX que agrupan RFs, corte del MVP, verificación de trazabilidad |
| `docs/05-stack-sugerido.md` | Stack recomendado + alternativa, justificado por RNF y restricciones |

**Ubicación:** si trabajas dentro de un repositorio o proyecto con sistema de archivos, crea los archivos en `docs/` en la raíz. En un chat sin repositorio, crea los archivos y preséntalos al usuario para descarga.

### Fase 4 — Cierre

Entrega con un resumen de 3-5 líneas: cuántos RF/RNF resultaron, qué quedó fuera del MVP y cuál es el siguiente paso natural (diseño de arquitectura, prototipo, validación con usuarios). Ofrece iterar sobre cualquier documento específico.

## Convenciones

- **IDs:** `RF-001`, `RNF-001` (tres dígitos, correlativos), `F-01` para features (dos dígitos). Si al iterar se elimina un requisito, su ID no se reutiliza: se marca como *Retirado*.
- **Prioridad MoSCoW:** `Must` / `Should` / `Could` / `Won't` (este último significa "no en esta versión", coherente con el out-of-scope).
- **Redacción de RF:** "El sistema debe [verbo en acción verificable]...". Adjetivos ambiguos ("rápido", "fácil", "seguro") no van en RF: van en RNF con métrica.
- **RNF con métrica:** "las búsquedas responden en menos de 2 s con 1 000 registros", no "el sistema debe ser rápido". Si el usuario no puede dar el número, propón uno razonable y márcalo como supuesto.
- **Trazabilidad bidireccional:** cada RF pertenece a exactamente una feature; cada feature lista sus RFs. Ningún RF huérfano, ninguna feature vacía.
- **Criterios de aceptación:** 1-3 por RF, como condiciones verificables. Usa formato Dado/Cuando/Entonces solo si el flujo lo amerita.
- **Idioma:** el mismo en que el usuario describe su idea.

## Anti-patrones

- Inventar requisitos que el usuario nunca mencionó ni confirmó (alucinación de requisitos).
- Hacer más de 4 preguntas en un mismo turno o re-preguntar lo que el usuario ya dijo.
- Generar documentos saltándose el checkpoint de la Fase 2.
- Presentar el stack como decisión cerrada: es una sugerencia argumentada; la decisión final es del usuario.
- Entrar en diseño de arquitectura detallado (diagramas de componentes, esquemas de BD, contratos de API): eso pertenece a la fase siguiente del proyecto.
