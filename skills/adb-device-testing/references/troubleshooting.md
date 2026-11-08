# Problemas conocidos (probados en un nubia Z2464N, Android 15, Chrome 137)

Cuándo: algo falla al usar `adb-phone.sh`, `cdp.mjs` o la sonda. Cada fila salió de una falla real.

| Síntoma | Causa | Arreglo |
|---|---|---|
| `adb devices` vacío o `no devices/emulators found` a mitad de sesión | el servidor adb quedó mudo | `adb-phone.sh devices` lo reinicia (`kill-server`, `start-server`); revisar cable y modo de transferencia de archivos |
| `unauthorized` | falta aceptar la clave RSA | aceptar el aviso en el teléfono y repetir |
| `adb: command not found` | platform-tools fuera del PATH | `adb-phone.sh find` (busca `ANDROID_HOME`, `~/Android/Sdk`, `/usr/lib/android-sdk`) |
| `wake` dice que está bloqueado | el bloqueo es seguro (PIN, patrón, huella) | el usuario lo desbloquea; la skill nunca lo intenta. `wm dismiss-keyguard` solo funciona con bloqueo no seguro |
| `await` agota el tiempo aunque la página reportó | otro `perf_listener.py` (de una corrida anterior) ocupa el puerto y recibe los resultados en su propio archivo | el listener ahora falla si el puerto está ocupado; apagar el anterior (`lsof -ti:9000`) |
| La página queda en "warming up", `max` enorme | pantalla apagada o pestaña en segundo plano: `requestAnimationFrame` pausado | `wake`, repetir |
| `cdp` dice que no hay socket `chrome_devtools_remote` | Chrome recién arrancado o sin página al frente (el socket apareció tras cargar páginas) | abrir una página, esperar y repetir; si no, sonda en página |
| `/json/version` vacío tras `adb forward` | socket existente pero sin respuesta | `stop` y volver a abrir Chrome; o sonda |
| `cdp.mjs`: `/json/new` da 500 `Could not create new page` | Chrome Android no crea pestañas por ese endpoint | `go` navega una pestaña existente; para una nueva usar `adb-phone.sh open` |
| `console.log` no aparece en `logcat` | Chrome de producción no vuelca la consola ahí | `cdp.mjs console <s>` (repite además los mensajes ya guardados) o la sonda |
| `ERR_CONNECTION_REFUSED` | falta el túnel o el servidor no escucha en el host | `adb-phone.sh up <puerto>`; el servidor debe aceptar conexiones del host |
| Página de error de certificado | HTTPS autofirmado en localhost | servir HTTP durante la prueba; restaurar lo apartado después |
| `ERR_UNSAFE_PORT` | puerto en la lista negra de Chrome (1, 7, 9, 6000, 6665-6669, 10080…) | elegir otro puerto |
| La URL se corta en `&` | el shell del teléfono la reinterpreta | `open` ya la protege con comillas simples; al llamar `adb shell` a mano usar `"'url'"` |
| Se acumulan pestañas | cada `open` crea una | `cdp.mjs close --match <texto>` o aceptarlo; `stop` cierra la app pero Chrome restaura pestañas |
| Captura negra o bloqueada | pantalla apagada | `wake` y repetir `shot` |
| Al escribir scripts: `cmd \| grep -q` falla con `set -o pipefail` | `grep -q` cierra la tubería y el productor recibe SIGPIPE | capturar la salida en una variable y comparar |
