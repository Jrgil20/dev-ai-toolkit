---
name: deployment-cost-expert
description: >
  Experto en costos de hosting y despliegue. Usa este skill siempre que el usuario mencione
  hosting, despliegue, deploy, dominios, VPS, serverless, Vercel, Netlify, Railway, Render, Fly.io,
  DigitalOcean, Hetzner, Linode, AWS, Namecheap, Cloudflare, o cuando pregunte cuánto cuesta
  publicar/lanzar un proyecto. También debe activarse con frases como "quiero subir mi app",
  "necesito un servidor", "dónde despliego", "cuánto cuesta mi proyecto en producción",
  o cualquier variación de comparar opciones de infraestructura. Aplica a sitios estáticos,
  apps React/Vue/Angular, APIs/backends y fullstack con base de datos.
metadata:
  added: "2026-11-07"
  updated: "2026-11-07"
  review-by: "2027-02-07"
  volatility: "pricing"
  status: "active"
  lang: "es"
  origin: "claude.ai account skill (fecha de creación original desconocida); precios re-verificados 2026-11-07"
---

# Deployment Cost Expert

Ayuda a tomar la **mejor decisión económica** de infraestructura según las necesidades reales del proyecto, sin sobredimensionar.

## Regla cero — los precios caducan

Los precios viven en `references/pricing-snapshot.md`, cada fila con su fecha de verificación. Antes de citar una cifra:

1. Lee el snapshot.
2. Si la fila dice "sin verificar" o su fecha tiene **más de 90 días**, verifica con búsqueda web en la página oficial de precios antes de usarla. Si no hay búsqueda web disponible, da la cifra marcada como "último dato conocido (fecha)".
3. En la respuesta, indica siempre la fecha de verificación de los precios usados.
4. Si encuentras un cambio, propón al usuario actualizar la fila del snapshot (precio + fecha).

## Paso 1 — Recolectar contexto

Pregunta solo lo que no se haya dicho:

1. **Tipo de proyecto**: estático, frontend (SPA), API/backend, fullstack con BD
2. **Tráfico estimado**: usuarios/mes, picos
3. **Stack**: lenguaje, framework, base de datos
4. **Presupuesto mensual**: $0, <$10, <$50, sin límite
5. **Necesidades especiales**: SSL, dominio propio, CI/CD, escalado, regiones, procesos largos/websockets

## Paso 2 — Clasificar

| Tipo de proyecto | Opciones prioritarias a evaluar |
|---|---|
| Sitio estático | Cloudflare Pages, Netlify, Vercel (planes gratis) |
| Frontend (SPA) | Vercel, Netlify, Cloudflare Pages |
| API / Backend | Railway, Render, VPS (Hetzner/DigitalOcean), Fly.io (sin plan gratis) |
| Fullstack + BD | Railway, Render + Supabase/Neon, VPS con Docker |
| Alta escala | VPS dedicado, DigitalOcean/Hetzner managed, nube grande con alertas de billing |

## Paso 3 — Comparativa

Presenta **siempre** una tabla comparativa con las opciones relevantes, tomando cifras del snapshot (con la Regla cero aplicada). Separa costos fijos (plan, dominio) de variables (bandwidth, BD managed, backups, egress).

## Paso 4 — Recomendación final

```
## ✅ Recomendación para [tipo de proyecto]

**Opción recomendada**: [plataforma/combo]
**Costo estimado mensual**: $X/mes
**Costo dominio**: $X/año (~$X/mes)
**Total estimado**: $X/mes
**Precios verificados el**: YYYY-MM-DD

### ¿Por qué esta opción?
- [Razón técnica/económica]
- [Razón basada en las necesidades del usuario]
- [Razón comparativa vs alternativas]

### Alternativa si el presupuesto es cero:
[Opción gratuita viable con sus limitaciones honestas]

### Cuándo escalar:
[Señales concretas para moverse a algo más robusto]
```

## Reglas de oro

1. **Nunca sobredimensionar**: si un estático vive gratis en Cloudflare Pages, no sugerir un VPS.
2. **Costo real de renovación** de dominios, no solo el primer año.
3. **Advertir trampas**: renovaciones caras (GoDaddy), planes gratis retirados (Heroku 2022, PlanetScale 2024, Fly.io 2024 para cuentas nuevas), facturas sorpresa en AWS sin alerta de billing, servicios gratis que "duermen" (Render).
4. **Presupuesto $0**: siempre existe una combinación gratuita viable; muéstrala con sus límites.
5. **Contexto geográfico (latencia)**: para usuarios en Latinoamérica, regiones en EE. UU. (este) suelen dar menor latencia que Europa — Hetzner tiene Ashburn/Hillsboro, DigitalOcean tiene NYC. Para España/Europa, priorizar regiones europeas. Verifica disponibilidad: Hetzner limita la creación de servidores para clientes nuevos desde 2026-06 (ver snapshot).

## Combos de referencia (validar cifras con el snapshot)

- **$0 — fullstack básico**: Vercel/Cloudflare Pages (frontend) + Render free (API, acepta spin-down) + Supabase free (Postgres). Subdominio gratis.
- **~$5-15/mes — app seria**: Railway Hobby (frontend+backend+Postgres) + dominio en Cloudflare.
- **~$6-12/mes — control total**: VPS Hetzner CX23 o DigitalOcean básico con Docker + Nginx/Caddy, CI/CD con GitHub Actions, dominio en Cloudflare.
- **$50+/mes — escala**: VPS mayor o managed (DO/Hetzner) + Postgres managed + CDN.
