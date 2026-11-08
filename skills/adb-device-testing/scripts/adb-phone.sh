#!/usr/bin/env bash
# adb-phone.sh — probar una app web local en un teléfono Android conectado por USB.
#
#   adb-phone.sh find                      # ruta de adb
#   adb-phone.sh devices                   # lista y valida el dispositivo (reinicia el servidor adb si no aparece)
#   adb-phone.sh info                      # modelo, Android, GPU/hardware, pantalla, Hz, RAM, batería
#   adb-phone.sh cdp                       # abre el túnel de DevTools si Chrome lo expone (0 = listo, 1 = no)
#   adb-phone.sh up 5173 3001 9000         # adb reverse de cada puerto + pantalla siempre encendida
#   adb-phone.sh wake                      # enciende la pantalla (rAF se pausa con la pantalla apagada); falla si hay PIN
#   adb-phone.sh open 'http://localhost:5173/?x=1&y=2' [paquete]   # abre la URL en una pestaña nueva (Chrome por defecto)
#   adb-phone.sh await FILE ANTES [SEG]    # espera a que FILE tenga más de ANTES líneas y muestra la última
#   adb-phone.sh shot captura.png          # captura de pantalla
#   adb-phone.sh stop [paquete]            # cierra la app
#   adb-phone.sh down                      # quita túneles, restaura la pantalla, cierra Chrome
#
# Varios dispositivos: exporta ANDROID_SERIAL=<serial>. Solo toca el dispositivo indicado y solo estos ajustes:
# stay_on_while_plugged_in (se guarda y se restaura en `down`) y los túneles reverse/forward.
set -euo pipefail

STATE="${TMPDIR:-/tmp}/adb-device-testing.state"
PKG_DEFAULT="com.android.chrome"

die() { echo "adb-phone: $*" >&2; exit 1; }

find_adb() {
  command -v adb 2>/dev/null && return 0
  local d
  for d in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" /usr/lib/android-sdk /opt/android-sdk; do
    [[ -n "$d" && -x "$d/platform-tools/adb" ]] && { echo "$d/platform-tools/adb"; return 0; }
  done
  return 1
}

ADB="$(find_adb)" || die "no encuentro adb (PATH, ANDROID_HOME, ~/Android/Sdk). Instala platform-tools."
adb() { "$ADB" "$@"; }
sh_() { adb shell "$@" | tr -d '\r'; }

device_lines() { adb devices -l | tail -n +2 | sed '/^[[:space:]]*$/d'; }

cmd_devices() {
  local out; out="$(device_lines)"
  if [[ -z "$out" ]]; then  # el servidor adb a veces queda mudo: un reinicio lo arregla
    adb kill-server >/dev/null 2>&1 || true
    adb start-server >/dev/null 2>&1 || true
    sleep 2
    out="$(device_lines)"
  fi
  [[ -n "$out" ]] || die "no hay dispositivo: revisa el cable, la depuración USB y el modo de transferencia de archivos."
  echo "$out"
  grep -q "unauthorized" <<<"$out" && die "unauthorized: acepta la clave RSA en la pantalla del teléfono y repite."
  grep -q "offline" <<<"$out" && die "offline: desconecta y reconecta el cable."
  local n; n="$(grep -c " device " <<<"$out" || true)"
  if (( n > 1 )) && [[ -z "${ANDROID_SERIAL:-}" ]]; then die "hay $n dispositivos: exporta ANDROID_SERIAL=<serial>."; fi
}

# Despierta la pantalla y exige que no haya bloqueo. Nunca intenta desbloquear un teléfono con PIN, patrón o huella.
ensure_unlocked() {
  adb shell input keyevent KEYCODE_WAKEUP
  sleep 1
  # capturar y comparar: `| grep -q` con pipefail da falso negativo (SIGPIPE a dumpsys)
  locked() { local w; w="$(sh_ dumpsys window)"; [[ "$w" == *isKeyguardShowing=true* ]]; }
  if locked; then
    adb shell wm dismiss-keyguard >/dev/null 2>&1 || true  # solo funciona si el bloqueo no es seguro (deslizar)
    sleep 1
  fi
  if locked; then die "el teléfono está bloqueado: desbloquéalo tú (la skill no lo hace) y repite."; fi
}

cmd_info() {
  cmd_devices >/dev/null
  echo "modelo:      $(sh_ getprop ro.product.manufacturer) $(sh_ getprop ro.product.model)"
  echo "android:     $(sh_ getprop ro.build.version.release) (sdk $(sh_ getprop ro.build.version.sdk))"
  echo "hardware:    $(sh_ getprop ro.hardware) / egl: $(sh_ getprop ro.hardware.egl)"
  echo "pantalla:    $(sh_ wm size | tail -1 | sed 's/.*: //') @ $(sh_ wm density | tail -1 | sed 's/.*: //') dpi"
  echo "refresco:    $(sh_ dumpsys display | grep -o 'fps=[0-9.]*' | sort -u | tr '\n' ' ')"
  echo "ram:         $(sh_ grep MemTotal /proc/meminfo | awk '{printf "%.1f GB", $2/1048576}')"
  echo "batería:     $(sh_ dumpsys battery | awk '/level/{print $2 "%"}')"
  echo "pantalla on: $(sh_ dumpsys power | grep -o 'mWakefulness=[A-Za-z]*' | head -1)"
  echo "bloqueado:   $(sh_ dumpsys window | grep -o 'isKeyguardShowing=[a-z]*' | head -1)"
}

cmd_cdp() {
  cmd_devices >/dev/null
  local port="${CDP_PORT:-9222}" socks v
  socks="$(sh_ "grep devtools_remote /proc/net/unix" 2>/dev/null || true)"
  if [[ "$socks" != *"@chrome_devtools_remote"* ]]; then
    echo "sin socket chrome_devtools_remote: Chrome recién arrancado o sin página en primer plano."
    echo "Abre una página con Chrome al frente y repite, o usa la sonda en página (references/perf-probe.md)."
    return 1
  fi
  adb forward "tcp:$port" localabstract:chrome_devtools_remote >/dev/null
  v="$(curl -s -m 5 "http://127.0.0.1:$port/json/version" || true)"
  if [[ -z "$v" ]]; then
    adb forward --remove "tcp:$port" >/dev/null 2>&1 || true
    echo "el socket existe pero no responde: ciérralo y ábrelo de nuevo (am force-stop), o usa la sonda en página."
    return 1
  fi
  grep -o '"Browser": "[^"]*"' <<<"$v"
  echo "CDP listo en 127.0.0.1:$port (node cdp.mjs targets|go|eval|shot|console|close)"
}

cmd_up() {
  [[ $# -ge 1 ]] || die "uso: up PUERTO..."
  cmd_devices >/dev/null
  if [[ ! -f "$STATE" ]]; then  # solo guarda el valor original la primera vez
    echo "stay_on=$(sh_ settings get global stay_on_while_plugged_in)" > "$STATE"
  fi
  adb shell svc power stayon true
  local p
  for p in "$@"; do adb reverse "tcp:$p" "tcp:$p" >/dev/null && echo "reverse tcp:$p"; done
}

cmd_open() {
  [[ $# -ge 1 ]] || die "uso: open URL [paquete]"
  local url="$1" pkg="${2:-$PKG_DEFAULT}"
  cmd_devices >/dev/null
  ensure_unlocked
  # las comillas simples viajan hasta el shell del teléfono: sin ellas `&` corta la URL
  adb shell am start -a android.intent.action.VIEW -d "'$url'" -f 0x10000000 "$pkg" | tail -1
}

cmd_await() {
  local file="$1" before="${2:-0}" timeout="${3:-120}" t0; t0=$(date +%s)
  while (( $(date +%s) - t0 < timeout )); do
    if [[ -f "$file" ]] && (( $(wc -l < "$file") > before )); then tail -1 "$file"; return 0; fi
    sleep 2
  done
  die "sin resultado en ${timeout}s (¿pestaña en segundo plano, pantalla apagada o túnel caído?)."
}

cmd_shot() {
  [[ $# -ge 1 ]] || die "uso: shot archivo.png"
  cmd_devices >/dev/null
  ensure_unlocked
  adb exec-out screencap -p > "$1"
  [[ "$(head -c 4 "$1" | tail -c 3)" == "PNG" ]] || die "la captura no es un PNG válido (¿pantalla bloqueada?)."
  echo "$1 ($(wc -c < "$1") bytes)"
}

cmd_stop() { adb shell am force-stop "${1:-$PKG_DEFAULT}"; }

cmd_down() {
  adb reverse --remove-all >/dev/null 2>&1 || true
  adb forward --remove-all >/dev/null 2>&1 || true
  if [[ -f "$STATE" ]]; then
    local prev; prev="$(sed -n 's/^stay_on=//p' "$STATE")"
    [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
    adb shell settings put global stay_on_while_plugged_in "$prev"
    rm -f "$STATE"
  fi
  adb shell am force-stop "$PKG_DEFAULT" || true
  echo "túneles cerrados, pantalla restaurada, $PKG_DEFAULT cerrado"
}

case "${1:-}" in
  find) echo "$ADB" ;;
  devices) cmd_devices ;;
  info) cmd_info ;;
  cdp) cmd_cdp ;;
  wake) cmd_devices >/dev/null; ensure_unlocked; echo "pantalla encendida y sin bloqueo" ;;
  up) shift; cmd_up "$@" ;;
  open) shift; cmd_open "$@" ;;
  await) shift; cmd_await "$@" ;;
  shot) shift; cmd_shot "$@" ;;
  stop) shift; cmd_stop "$@" ;;
  down) cmd_down ;;
  *) sed -n '2,17p' "$0"; exit 2 ;;
esac
