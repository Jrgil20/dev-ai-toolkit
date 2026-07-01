---
name: clean-architecture
description: Convenciones de Clean Architecture en 4 capas (Domain, Application, Interface Adapters, Infrastructure), regla de dependencias y nomenclatura de puertos/adaptadores. Usar siempre que se diseñe, escriba o revise código en un proyecto por capas, se pregunte "¿en qué capa va esto?", "¿esto viola la arquitectura?", o se cree un módulo nuevo en un proyecto con estructura domain/application/infrastructure.
---

# Clean Architecture

Aplica estas convenciones al escribir, ubicar o revisar código en proyectos por capas. La regla única de la que deriva todo: **las dependencias apuntan hacia adentro** (Infrastructure → Interface Adapters → Application → Domain). El dominio no conoce a nadie.

## Las 4 capas y qué vive en cada una

1. **Domain**: entidades, value objects, aggregates, eventos de dominio, servicios de dominio, **puertos** (interfaces). Cero imports de frameworks, ORMs, HTTP o SDKs.
2. **Application**: casos de uso que orquestan el dominio. Depende solo de Domain (usa sus puertos). Define DTOs de entrada/salida del caso de uso.
3. **Interface Adapters**: controladores, presenters, mappers DTO↔dominio, handlers de CLI/bot. Traduce el mundo exterior al lenguaje de Application.
4. **Infrastructure**: **adaptadores** que implementan los puertos (repositorios con ORM, clientes HTTP, filesystem, colas), configuración, composición de dependencias (el único lugar donde se instancia todo).

## Test de ubicación (aplícalo en orden)

Para decidir dónde va una pieza de código nueva:

1. ¿Expresa una regla de negocio que sería cierta sin computadoras? → **Domain**.
2. ¿Coordina pasos de dominio para cumplir una intención del usuario? → **Application** (caso de uso).
3. ¿Traduce formatos entre el exterior y los casos de uso? → **Interface Adapters**.
4. ¿Habla con algo externo (DB, red, disco, reloj, random)? → **Infrastructure**, detrás de un puerto definido en Domain o Application.

## Nomenclatura

- Puerto: interfaz nombrada por capacidad, en el lado del consumidor. Ej: `RecipeRepository`, `NotificationSender`, `Clock`.
- Adaptador: implementación nombrada por tecnología + puerto. Ej: `PostgresRecipeRepository`, `TwilioNotificationSender`, `SystemClock`.
- Caso de uso: verbo + sustantivo. Ej: `RegisterCheckIn`, `GenerateUsageReport`.

## Al revisar código

Verifica la dirección de imports mecánicamente: ningún archivo de `domain/` importa de `application/`, `adapters/` ni `infrastructure/`; ningún archivo de `application/` importa de capas externas. Para el checklist detallado de violaciones frecuentes y cómo corregirlas, lee `references/dependency-rules.md` (léelo solo cuando estés auditando o encuentres una violación dudosa).
