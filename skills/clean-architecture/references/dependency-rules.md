# Checklist de violaciones de dependencias

Referencia de auditoría. Cargar solo durante revisiones de arquitectura.

## Cómo detectar mecánicamente

Busca imports prohibidos con grep sobre cada capa (ajusta rutas al proyecto):

```bash
# Domain importando hacia afuera (debe dar 0 resultados)
grep -rnE "from (application|adapters|infrastructure)|import (sqlalchemy|fastapi|requests|boto3|prisma)" src/domain/

# Application importando infraestructura (debe dar 0 resultados)
grep -rnE "from (adapters|infrastructure)|import (sqlalchemy|fastapi|requests)" src/application/
```

## Catálogo de violaciones frecuentes

### V1 — Framework en el dominio
**Síntoma**: entidad con decoradores de ORM (`@Entity`, `Base` de SQLAlchemy, modelos de Django) o tipos de framework en firmas.
**Corrección**: entidad pura en Domain; modelo de persistencia separado en Infrastructure + mapper en el repositorio.

### V2 — Caso de uso instanciando adaptadores
**Síntoma**: `PostgresRepo()` o `TwilioClient()` dentro del caso de uso.
**Corrección**: el caso de uso recibe el puerto por constructor; la instanciación vive solo en el composition root (Infrastructure).

### V3 — DTO/entidad del dominio expuesto en la API
**Síntoma**: el controlador serializa la entidad directamente como respuesta HTTP.
**Corrección**: presenter/mapper en Interface Adapters que produce un DTO de respuesta. Cambios de API dejan de forzar cambios de dominio.

### V4 — Lógica de negocio en el controlador
**Síntoma**: `if` de reglas de negocio, cálculos o validaciones de invariantes en el handler HTTP/bot.
**Corrección**: mover a caso de uso (orquestación) o a la entidad/VO (invariantes).

### V5 — Puerto definido en Infrastructure
**Síntoma**: la interfaz vive junto a su implementación; Application importa desde `infrastructure/`.
**Corrección**: el puerto se declara en la capa que lo consume (Domain o Application); Infrastructure solo lo implementa.

### V6 — Dependencia oculta del reloj/random/env
**Síntoma**: `datetime.now()`, `random()`, `os.environ` dentro de Domain o Application.
**Corrección**: puertos `Clock`, `RandomSource`, config inyectada. Hace la lógica testeable de forma determinista.

### V7 — Transacción manejada en el dominio
**Síntoma**: `session.commit()` o manejo de transacciones dentro de entidades o servicios de dominio.
**Corrección**: la unidad de trabajo se controla en Application (o en un decorador de caso de uso en Infrastructure).

## Formato de reporte de auditoría

```markdown
# Auditoría de arquitectura: [proyecto]
## Resumen
| Capa | Archivos | Violaciones |
## Violaciones
| # | Regla | Ubicación | Evidencia (import/línea) | Corrección |
## Deuda aceptable
(violaciones conscientes con justificación, si las hay)
```
