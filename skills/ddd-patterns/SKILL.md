---
name: ddd-patterns
description: Patrones tácticos de Domain-Driven Design (Entity, Value Object, Aggregate, Repository, Domain Event, Domain Service) con criterios deterministas para elegir entre ellos, y catálogo de antipatrones (Primitive Obsession, Anemic Domain Model). Usar siempre que se modele dominio, se pregunte "¿esto es entity o value object?", "¿dónde va esta regla?", se diseñe un aggregate, o se detecte lógica de negocio dispersa fuera del dominio.
---

# Patrones Tácticos DDD

Aplica estos criterios al modelar dominio. Objetivo: que las reglas de negocio vivan en objetos de dominio ricos, con invariantes protegidas en el constructor y métodos con nombre de negocio.

## Árbol de decisión (aplícalo en orden)

Para cada concepto del dominio:

1. **¿Su identidad importa a lo largo del tiempo aunque cambien sus atributos?**
   - Sí → **Entity** (tiene `id`; igualdad por identidad).
   - No → **Value Object** (inmutable; igualdad por valor; se reemplaza, no se muta).
2. **¿Es una Entity que agrupa otras piezas bajo invariantes comunes?**
   - Sí → **Aggregate Root**. Todo acceso externo pasa por la raíz; las referencias entre aggregates son por id, nunca por objeto.
3. **¿Es una regla que no pertenece naturalmente a una sola Entity/VO?**
   - Sí → **Domain Service** (sin estado, nombrado por la operación de negocio).
4. **¿Algo relevante del negocio acaba de suceder y otros deben reaccionar?**
   - Sí → **Domain Event** (nombre en pasado: `CheckInRegistered`, `OrderApproved`).
5. **¿Necesitas obtener/persistir aggregates?**
   - → **Repository**: un puerto por aggregate root, con métodos de intención (`find_active_by_venue`), no CRUD genérico filtrable.

## Reglas de construcción

- Constructores (o factory methods) validan TODAS las invariantes: un objeto de dominio inválido no puede existir.
- Los VOs encapsulan primitivas con reglas: `Email`, `Money`, `Coordinates` — nunca `str` y `float` sueltos cruzando firmas.
- Métodos de Entity con lenguaje de negocio: `arrow.extend_to(cell)` en vez de `arrow.segments.append(...)` desde afuera.
- Un aggregate = un límite transaccional. Si necesitas modificar dos aggregates "a la vez", usa un Domain Event y consistencia eventual, o revisa el diseño del límite.

**Ejemplo:**
Input: "guardo el email del usuario como string y lo valido en el endpoint"
Output: VO `Email` que valida formato en su constructor; el endpoint solo construye `Email(raw)` y deja que el dominio rechace lo inválido.

## Antipatrones

Al revisar o refactorizar dominio, consulta `references/antipatterns.md` — catálogo con síntomas y refactorización paso a paso de: Primitive Obsession, Anemic Domain Model, y manejo de servicios externos (Circuit Breaker, ACL, retries). Léelo solo cuando detectes uno de esos olores o el usuario pida auditar el modelo.
