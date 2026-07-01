---
name: tech-docs
description: Escribe documentación técnica con plantillas fijas para README y ADRs (Architecture Decision Records). Usar siempre que el usuario pida "documenta esto", "crea el README", "registra esta decisión", "necesito un ADR", "escribe la documentación de X", o al cerrar una decisión arquitectónica que deba quedar registrada.
---

# Documentación Técnica

Produce documentación en prosa clara con las plantillas fijas de abajo. Principio: la documentación explica lo que el código no puede decir por sí mismo — decisiones, contexto, cómo empezar. No parafrasees el código.

## README (plantilla)

```markdown
# [Nombre del proyecto]
(1-2 líneas: qué es y qué problema resuelve)

## Stack
(lenguaje, framework, dependencias clave — solo lo decisivo)

## Arquitectura
(3-6 líneas: capas o módulos principales y cómo se comunican;
enlazar a ADRs si existen)

## Setup
(pasos numerados, copiables, verificados; incluir versión mínima
de runtime y variables de entorno con ejemplo `.env.example`)

## Comandos
| Comando | Qué hace |

## Estructura del repo
(árbol de 1 nivel con comentario por directorio)
```

## ADR (plantilla)

Archivo: `docs/adr/NNNN-titulo-en-kebab.md`, numeración incremental.

```markdown
# ADR-NNNN: [Título de la decisión]

- **Estado**: Propuesto | Aceptado | Reemplazado por ADR-XXXX
- **Fecha**: YYYY-MM-DD

## Contexto
(qué problema o fuerza motiva la decisión; restricciones reales)

## Decisión
(qué se decidió, en una frase afirmativa + detalle breve)

## Alternativas consideradas
| Opción | Pros | Contras | Por qué se descartó |

## Consecuencias
(positivas Y negativas; qué se vuelve más fácil y qué más difícil)
```

## Reglas

- Prosa directa en el idioma del proyecto; frases cortas; imperativo en instrucciones.
- Todo paso de setup debe ser ejecutable tal cual está escrito — sin "configura X apropiadamente".
- Un ADR registra UNA decisión. Decisiones distintas = ADRs distintos.
- Fecha y estado siempre presentes en ADRs; un ADR aceptado no se edita, se reemplaza.
- Si el usuario pide "documentar" sin especificar formato, pregunta si quiere README, ADR u otro antes de asumir.
