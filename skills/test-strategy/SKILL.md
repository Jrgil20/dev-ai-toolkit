---
name: test-strategy
description: Diseño de tests con priorización determinista (qué testear primero), patrón AAA, nomenclatura estándar y estructura por tipo de test. Usar siempre que el usuario pida escribir tests, "agrega tests para X", "¿cómo testeo esto?", "necesito cobertura", o cuando se implemente lógica nueva sin tests, incluso si el usuario no los pidió explícitamente (proponerlos).
---

# Test Strategy

Diseña y escribe tests siguiendo prioridades fijas y estructura AAA. El objetivo es cobertura útil (comportamiento y casos borde), no cobertura de línea inflada.

## Priorización (orden fijo)

Al decidir qué testear primero:

1. **Lógica de dominio / reglas de negocio** — el código que decide, calcula o valida.
2. **Casos borde conocidos** — nulos, vacíos, límites numéricos, colecciones de 0/1/N elementos.
3. **Manejo de errores** — que los fallos esperados produzcan el error correcto, no otro.
4. **Integraciones críticas** — persistencia y contratos con servicios externos (con dobles de test).
5. **Camino feliz de orquestación** — casos de uso end-to-end.

NO priorices: getters/setters, código trivial de framework, UI puramente presentacional.

## Estructura de cada test: AAA

```python
def test_descuento_no_aplica_bajo_monto_minimo():
    # Arrange
    carrito = Carrito(items=[item_de(monto=9.99)])
    # Act
    total = calcular_total(carrito, cupon="DESC10")
    # Assert
    assert total == Decimal("9.99")
```

Un comportamiento por test. Si necesitas dos bloques Act/Assert, son dos tests.

## Nomenclatura

Formato: `test_<comportamiento>_<condición>` en el idioma del codebase.

**Ejemplo 1:** Input: verifica que login falla con password incorrecto → Output: `test_login_falla_con_password_incorrecto`
**Ejemplo 2:** Input: verifica que el aggregate rechaza estado inválido → Output: `test_arrow_rechaza_segmento_fuera_del_tablero`

## Dobles de test

- **Stub** para respuestas fijas de dependencias (repos en memoria).
- **Mock** solo cuando el comportamiento a verificar ES la interacción (ej: "se envió la notificación").
- Nunca mockees lo que estás testeando; nunca mockees tipos que no posees (envuelve primero en un puerto/adapter).

## Formato de salida al proponer una estrategia

```markdown
# Plan de tests: [módulo]
## Casos priorizados
| # | Prioridad | Caso | Tipo (unit/integration) |
## Dobles necesarios
## Casos descartados y por qué
```

Al escribir los tests, entrega el archivo completo listo para ejecutar, con imports y fixtures incluidos.
