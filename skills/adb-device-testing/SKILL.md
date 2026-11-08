---
name: adb-device-testing
description: "Trigger: probar en el teléfono, celular Android, adb, adb reverse, medir fps en el móvil, captura del teléfono, DevTools de Chrome Android. Prueba una app web local en un Android por USB y mide rendimiento real."
metadata:
  added: "2026-11-08"
  updated: "2026-11-08"
  review-by: "2027-05-08"
  volatility: "tooling"
  status: "active"
  lang: "es"
  origin: "own"
---

# Prueba en teléfono Android (adb)

## Activation Contract

Usar cuando haya que ver, depurar o medir una app web local en un Android conectado por USB (Chrome). No aplica a emuladores ni a apps nativas.

## Hard Rules

- Tocar solo el dispositivo del usuario. Con varios conectados, pedir el serial y exportar `ANDROID_SERIAL`.
- Prohibido: `adb root`, `su`, `adb tcpip` o emparejado inalámbrico, `install`, `uninstall`, `pm clear`, `rm`, leer mensajes, fotos o contactos, escribir un PIN o saltar un bloqueo seguro.
- Solo se cambian los túneles `reverse`/`forward` y `stay_on_while_plugged_in`; `adb-phone.sh down` lo restaura todo al terminar.
- El teléfono debe estar desbloqueado y con la pantalla encendida: apagada pausa `requestAnimationFrame` y falsea toda medición. Si `wake` falla, pedir al usuario que lo desbloquee y detenerse.
- Chrome rechaza HTTPS autofirmado en localhost y los puertos de su lista negra (`ERR_UNSAFE_PORT`): servir HTTP durante la prueba y restaurar lo que se haya apartado (por ejemplo `.certs`).
- Toda instrumentación temporal en la app lleva el marcador `TEMP-PERF` y se revierte; comprobarlo con `grep`.

## Decision Gates

| Necesito | Camino |
|---|---|
| Ver cómo se ve | `open` + `shot` |
| Leer consola y errores, evaluar JS, navegar | `adb-phone.sh cdp` y `scripts/cdp.mjs` |
| Medir fps o draw calls | sonda en página + `perf_listener.py` (no depende de CDP) |
| `cdp` dice que no hay socket | abrir una página con Chrome al frente y repetir; si sigue, usar la sonda |
| Varias corridas | `stop` entre ellas, dos pasadas, descartar las inválidas |

## Execution Steps

1. `scripts/adb-phone.sh devices` y `info`: anotar modelo, GPU, Hz, viewport y DPR para el reporte.
2. `adb-phone.sh wake`.
3. Servir la app por HTTP y `adb-phone.sh up <puertos de la app> [9000]`.
4. `adb-phone.sh open '<url>'` (comillas simples si la URL lleva `&`).
5. Observar: `shot`, o `cdp` y `node scripts/cdp.mjs console|eval|go|shot|targets|close`.
6. Medir: `python3 scripts/perf_listener.py out.jsonl`, sonda en la página (`references/perf-probe.md`), `adb-phone.sh await out.jsonl <líneas previas>`.
7. Validar cada corrida con los criterios de `references/perf-probe.md`; repetir hasta tener dos válidas.
8. `adb-phone.sh down`, revertir la instrumentación y restaurar lo apartado.

## Output Contract

Reportar: dispositivo (modelo, Android, GPU, viewport y DPR, Hz), camino usado, cada corrida (valor y las descartadas con su motivo), lo que no se midió, y confirmar que se restauraron túneles, pantalla e instrumentación.

## References

- `scripts/adb-phone.sh`: `find|devices|info|cdp|wake|up|open|await|shot|stop|down`.
- `scripts/cdp.mjs`: cliente mínimo de DevTools (Node 22 o superior).
- `scripts/perf_listener.py`: recibe las mediciones que la página envía.
- `assets/fps-probe.html`: prueba de humo y plantilla de la sonda.
- `references/perf-probe.md`: sonda, validez de corridas y lectura de resultados.
- `references/troubleshooting.md`: síntoma, causa y arreglo.
