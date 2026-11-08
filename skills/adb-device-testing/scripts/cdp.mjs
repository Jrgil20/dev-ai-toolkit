#!/usr/bin/env node
// cdp.mjs — cliente mínimo del protocolo de DevTools para el Chrome de un teléfono Android.
// Requiere Node >= 22 (WebSocket global) y el túnel: `adb-phone.sh cdp` (adb forward tcp:9222 -> chrome_devtools_remote).
//
//   node cdp.mjs targets                       # pestañas abiertas
//   node cdp.mjs go <url>                      # navega la pestaña elegida a la URL (Page.navigate)
//   node cdp.mjs eval '<expresión JS>'         # evalúa en la página y imprime el resultado como JSON
//   node cdp.mjs shot <archivo.png>            # captura de la página
//   node cdp.mjs console <segundos>            # imprime console.* y excepciones durante N segundos
//   node cdp.mjs close                         # cierra las pestañas elegidas
//
// Opciones: --port 9222  --match <texto de la URL>  (sin --match se usa la primera pestaña de tipo page)
import { writeFileSync } from "node:fs";

if (typeof WebSocket === "undefined") {
  console.error("cdp.mjs necesita Node >= 22 (WebSocket global).");
  process.exit(2);
}

const argv = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = argv.indexOf(`--${name}`);
  if (i < 0) return fallback;
  const [, v] = argv.splice(i, 2);
  return v ?? fallback;
};
const port = opt("port", "9222");
const match = opt("match", "");
const [cmd, ...rest] = argv;
const base = `http://127.0.0.1:${port}`;

async function json(path, init) {
  const r = await fetch(`${base}${path}`, init);
  if (!r.ok) throw new Error(`${path}: HTTP ${r.status}`);
  return r.json();
}

async function pageTargets() {
  const all = await json("/json");
  return all.filter((t) => t.type === "page" && t.url.includes(match));
}

async function connect(target) {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = () => rej(new Error("no se pudo abrir el WebSocket de la pestaña")); });
  let id = 0;
  const pending = new Map();
  const listeners = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pending.has(d.id)) {
      const p = pending.get(d.id);
      pending.delete(d.id);
      d.error ? p.rej(new Error(d.error.message)) : p.res(d.result);
    } else if (d.method) listeners.forEach((l) => l(d));
  };
  const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
  return { send, on: (l) => listeners.push(l), close: () => ws.close() };
}

// Un argumento de console.* viene como RemoteObject: valor primitivo, o vista previa de propiedades para objetos.
function fmt(a) {
  if (a.value !== undefined) return typeof a.value === "string" ? a.value : JSON.stringify(a.value);
  if (a.preview?.properties) return `{${a.preview.properties.map((p) => `${p.name}: ${p.value}`).join(", ")}${a.preview.overflow ? ", …" : ""}}`;
  return a.description ?? a.type;
}

async function main() {
  switch (cmd) {
    case "targets": {
      for (const t of await pageTargets()) console.log(`${t.id}  ${t.url}`);
      return;
    }
    case "go": {
      // /json/new no funciona en Chrome Android (probado: 500 "Could not create new page"): se navega una pestaña existente.
      const url = rest[0];
      if (!url) throw new Error("uso: go <url>");
      const [t] = await pageTargets();
      if (!t) throw new Error("no hay pestañas: abre una con `adb-phone.sh open <url>`");
      const c = await connect(t);
      const r = await c.send("Page.navigate", { url });
      c.close();
      if (r.errorText) throw new Error(`navegación fallida: ${r.errorText}`);
      console.log(`${t.id}  -> ${url}`);
      return;
    }
    case "eval": {
      const [t] = await pageTargets();
      if (!t) throw new Error("no hay pestañas que coincidan");
      const c = await connect(t);
      const r = await c.send("Runtime.evaluate", { expression: rest[0], awaitPromise: true, returnByValue: true });
      c.close();
      if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description ?? r.exceptionDetails.text);
      console.log(JSON.stringify(r.result.value));
      return;
    }
    case "shot": {
      const [t] = await pageTargets();
      if (!t) throw new Error("no hay pestañas que coincidan");
      const c = await connect(t);
      const r = await c.send("Page.captureScreenshot", { format: "png" });
      c.close();
      writeFileSync(rest[0], Buffer.from(r.data, "base64"));
      console.log(`${rest[0]} (${Buffer.from(r.data, "base64").length} bytes)`);
      return;
    }
    case "console": {
      const seconds = Number(rest[0] ?? 5);
      const [t] = await pageTargets();
      if (!t) throw new Error("no hay pestañas que coincidan");
      const c = await connect(t);
      c.on((d) => {
        if (d.method === "Runtime.consoleAPICalled") console.log(`[${d.params.type}] ${d.params.args.map(fmt).join(" ")}`);
        if (d.method === "Runtime.exceptionThrown") console.log(`[exception] ${d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text}`);
      });
      await c.send("Runtime.enable");
      await new Promise((r) => setTimeout(r, seconds * 1000));
      c.close();
      return;
    }
    case "close": {
      for (const t of await pageTargets()) { await fetch(`${base}/json/close/${t.id}`); console.log(`closed ${t.id}`); }
      return;
    }
    default:
      console.error("comandos: targets | go <url> | eval <js> | shot <png> | console <s> | close   (--port, --match)");
      process.exit(2);
  }
}

main().catch((e) => { console.error(`cdp: ${e.message}`); process.exit(1); });
