# Snapshot de precios de hosting y dominios

> **Fecha del snapshot:** 2026-11-07 · **Revisar antes de:** 2027-02-07
>
> Columna **Verificado**: fecha en que la fila se contrastó con fuentes actuales. "Sin verificar" = valor heredado del skill original (claude.ai, fecha desconocida); trátalo como sospechoso y verifícalo antes de citarlo. Precios sin IVA, en la moneda del proveedor.

## PaaS

| Plataforma | Plan gratis | Pago desde | Ideal para | Limitaciones clave | Verificado |
|---|---|---|---|---|---|
| Vercel | Sí (Hobby, uso no comercial) | $20/mes (Pro) | Next.js, React, Vue | Serverless, sin procesos largos | Sin verificar |
| Netlify | Sí | ~$19/mes | Estáticos, JAMstack | Build minutes limitados en free | Sin verificar |
| Railway | Trial: $5 único (30 días) → plan Free con $1/mes de crédito | $5/mes Hobby (incluye $5 de uso); $20/mes Pro | APIs, backends, fullstack con BD | El Free es muy limitado; lo real empieza en Hobby | 2026-11-07 |
| Render | Sí (web services con spin-down) | ~$7/mes | APIs, workers, cron | El servicio free duerme tras inactividad | Sin verificar |
| Fly.io | **No** para cuentas nuevas (planes con allowance gratis retirados el 2024-10-07; solo trial de 2 h de máquina o 7 días) | Pago por uso, sin plan fijo | Contenedores, multi-región | Sin tope de gasto por defecto | 2026-11-07 |

## VPS

| Proveedor | Plan entrada | RAM / CPU | Precio/mes | Notas | Verificado |
|---|---|---|---|---|---|
| Hetzner Cloud | CX23 (reemplazó a CX22) | 2 vCPU / 4 GB | ≈ €5.4–6.0 según IPv4/región (subidas el 2026-04-01 y 2026-06-15) | Desde 2026-06-26 limita creación de servidores a clientes nuevos; confirmar disponibilidad | 2026-11-07 |
| DigitalOcean | Basic Droplet | 1 vCPU / 1 GB | ~$4–6 | Muy buena documentación | Sin verificar |
| Linode (Akamai) | Nanode | 1 vCPU / 1 GB | ~$5 | Red global estable | Sin verificar |
| Hetzner Dedicated | (el AX41 del skill original puede no existir ya) | — | — | Verificar línea actual | Sin verificar |

## Bases de datos gestionadas (gratis / entrada)

| Servicio | Plan gratis | Entrada de pago | Verificado |
|---|---|---|---|
| Supabase | Sí (Postgres, cuota limitada; proyectos se pausan por inactividad) | ~$25/mes Pro | Sin verificar |
| PlanetScale | **No** (Hobby retirado en abril 2024) | Desde $5/mes (Postgres single node) | 2026-11-07 |

## Dominios (.com)

| Registrador | Primer año | Renovación | Notas | Verificado |
|---|---|---|---|---|
| Cloudflare Registrar | ~$10.44 | Igual (precio costo) | DNS gratis, sin markup | Sin verificar |
| Porkbun | ~$9.73 | Similar | WHOIS privacy gratis | Sin verificar |
| Namecheap | ~$9.98 | ~$13–15 | Primer año barato | Sin verificar |
| GoDaddy | ~$12–20 | ~$22+ | Evitar: renovaciones caras | Sin verificar |

## Páginas oficiales para verificar

- https://www.hetzner.com/cloud/ · https://docs.hetzner.com/general/infrastructure-and-availability/price-adjustment/
- https://www.digitalocean.com/pricing/
- https://vercel.com/pricing · https://www.netlify.com/pricing/
- https://railway.com/pricing · https://docs.railway.com/reference/pricing
- https://render.com/pricing
- https://fly.io/docs/about/pricing/ · https://fly.io/docs/about/free-trial/
- https://planetscale.com/pricing · https://supabase.com/pricing
- https://www.cloudflare.com/products/registrar/

## Historial de cambios del snapshot

| Fecha | Cambio |
|---|---|
| 2026-11-07 | Snapshot creado desde el skill original. Corregidos: Fly.io (sin plan gratis para cuentas nuevas), PlanetScale (sin plan gratis), Hetzner (CX22→CX23, dos subidas en 2026, disponibilidad limitada), Railway (Trial/Free/Hobby/Pro). Resto marcado "sin verificar". |
