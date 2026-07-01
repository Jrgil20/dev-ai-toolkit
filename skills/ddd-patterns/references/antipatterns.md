# Antipatrones de dominio

Referencia de auditoría/refactorización. Cargar solo al detectar el olor correspondiente.

## A1 — Primitive Obsession

**Síntomas**: firmas con `str`, `int`, `float` que representan conceptos con reglas (`email: str`, `amount: float`, `phone: str`); la misma validación repetida en varios lugares; bugs por pasar argumentos en orden incorrecto (`transfer(from_acc, to_acc)` con dos strings).

**Refactorización (orden)**:
1. Crea el VO con validación en constructor y sin setters.
2. Reemplaza el primitivo en la firma más interna (dominio) primero.
3. Propaga hacia afuera capa por capa; los adapters construyen el VO en el borde.
4. Elimina las validaciones duplicadas que quedaron obsoletas.

```python
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str
    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Money no admite montos negativos")
        if len(self.currency) != 3:
            raise ValueError("currency debe ser código ISO-4217")
    def add(self, other: "Money") -> "Money":
        if other.currency != self.currency:
            raise CurrencyMismatch(self.currency, other.currency)
        return Money(self.amount + other.amount, self.currency)
```

## A2 — Anemic Domain Model

**Síntomas**: entidades que son bolsas de getters/setters; toda la lógica vive en "services" que leen y escriben campos ajenos; invariantes verificadas (o no) fuera del objeto.

**Refactorización (orden)**:
1. Lista las invariantes reales del concepto (qué combinaciones de estado son ilegales).
2. Mueve cada invariante al constructor/factory del objeto.
3. Convierte cada secuencia "get → decide → set" externa en UN método de negocio del objeto.
4. Elimina setters públicos; el estado cambia solo vía métodos con nombre de negocio.
5. Deja en los services únicamente la orquestación entre objetos.

**Test del olor**: si puedes poner el objeto en un estado inválido desde afuera, sigue anémico.

## A3 — Servicios externos sin frontera (integraciones frágiles)

**Síntomas**: el dominio o los casos de uso conocen excepciones del SDK externo (`TwilioRestException` en Application); un fallo del proveedor tumba el caso de uso completo; tipos del proveedor circulando por el dominio.

**Patrones de corrección**:
- **ACL (Anti-Corruption Layer)**: adapter que traduce tipos y errores del proveedor a tipos y errores del dominio. El dominio ve `NotificationFailed`, nunca `TwilioRestException`.
- **Retry con backoff exponencial + jitter**: solo para errores transitorios (timeouts, 429, 5xx); nunca para errores de negocio (400 de validación). Límite fijo de intentos.
- **Circuit Breaker**: tras N fallos consecutivos abre el circuito y falla rápido durante una ventana de enfriamiento; evita cascadas. Estados: cerrado → abierto → semiabierto.

**Orden de aplicación**: primero ACL (frontera limpia), luego retry (transitorios), luego breaker (protección sistémica). Implementar los tres en el adapter de Infrastructure, invisibles para Application.
