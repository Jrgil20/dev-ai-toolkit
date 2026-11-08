# Sonda de rendimiento en página

Cuándo: medir fps (y métricas de la app, como draw calls de three.js) en el Chrome del teléfono. Es el camino que siempre funciona: la página mide y reporta por HTTP a un listener local, sin depender de DevTools ni de `logcat` (Chrome de producción no imprime la consola ahí).

## Montaje

1. `python3 scripts/perf_listener.py out.jsonl --port 9000` (escucha solo en 127.0.0.1, una línea JSON por POST).
2. `adb-phone.sh up <puertos de la app> 9000` (el teléfono ve `localhost:9000` por `adb reverse`).
3. Añadir la sonda a la app, marcada `TEMP-PERF`. Plantilla completa y probada: `assets/fps-probe.html`. Núcleo:

```js
// TEMP-PERF: esperar a que cargue la escena, muestrear rAF y reportar
setTimeout(() => {
  const t = []; let last = performance.now(); const end = last + 10_000;
  const f = (n) => {
    t.push(n - last); last = n;
    if (n < end) return requestAnimationFrame(f);
    t.shift(); t.sort((a, b) => a - b);
    const q = (p) => t[Math.min(t.length - 1, Math.floor(t.length * p))];
    fetch("http://localhost:9000/perf", { method: "POST", mode: "no-cors", body: JSON.stringify({
      frames: t.length, fps: +(t.length / 10).toFixed(1), p50: +q(0.5).toFixed(1), p95: +q(0.95).toFixed(1), max: +t[t.length - 1].toFixed(1),
      dpr: devicePixelRatio, w: innerWidth, h: innerHeight /* + métricas de la app: renderer.info.render.calls, .triangles */ }) });
  };
  requestAnimationFrame(f);
}, 25_000); // asentamiento: carga de modelos y fusiones
```

4. Abrir la URL con un parámetro que active la sonda (por ejemplo `?perf=1`) y esperar: `adb-phone.sh await out.jsonl <líneas antes>`.

## Validar cada corrida (descartar y repetir si falla)

| Señal | Significa | Acción |
|---|---|---|
| `max` de cientos de ms a decenas de segundos | pestaña pausada (pantalla apagada o app en segundo plano) | `wake` y repetir |
| Métrica de contenido muy baja (triángulos, nodos) | la escena no terminó de cargar | más asentamiento y repetir |
| Resultado distinto del de la pasada anterior en más de ~10 % | corrida contaminada (carga fría, otra app, térmico) | tercera pasada |
| `visible` distinto de `visible` | la página no estaba al frente | `wake` y repetir |

## Leer los números

- Los fps salen en escalones (60, 30, 20, 15…) porque el vsync cuantiza; con pantallas de 90 o 120 Hz los escalones cambian. Comparar siempre contra el mismo modo de refresco.
- Dos pasadas por configuración y mismas condiciones (misma URL, brillo, cable, nada más abierto). La primera carga tras reiniciar el servidor es fría.
- Reportar viewport y DPR: en vertical se dibuja menos escena que en una ventana de escritorio, así que las cifras del teléfono no son comparables con las de la PC.
- El render por software (headless sin GPU) no sirve para fps absolutos; sí para contar draw calls.

## Al terminar

`adb-phone.sh down`; quitar la sonda (`grep -rn TEMP-PERF`); apagar el listener y el servidor de prueba.
