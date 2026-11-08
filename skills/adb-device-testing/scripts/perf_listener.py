#!/usr/bin/env python3
"""Receives measurements POSTed by a page running on the phone and appends them to a JSON-lines file.

    python3 perf_listener.py results.jsonl [--port 9000]

Why it exists: release Chrome on Android prints no console to logcat and exposes no DevTools socket on some devices,
so the page reports its own numbers. Reach this listener from the phone with `adb-phone.sh up 9000` (adb reverse).
Binds to 127.0.0.1 only, accepts POST bodies up to 64 KB, writes one compact JSON object per line.
"""
import argparse
import http.server
import json
import sys

MAX_BODY = 64 * 1024


def make_handler(path):
    class Handler(http.server.BaseHTTPRequestHandler):
        def _cors(self):
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Headers", "*")

        def do_OPTIONS(self):  # preflight, in case the page does not use no-cors
            self.send_response(204)
            self._cors()
            self.end_headers()

        def do_POST(self):
            n = int(self.headers.get("content-length", 0))
            if n <= 0 or n > MAX_BODY:
                self.send_response(413)
                self._cors()
                self.end_headers()
                return
            try:
                record = json.loads(self.rfile.read(n))
            except ValueError:
                self.send_response(400)
                self._cors()
                self.end_headers()
                return
            with open(path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, separators=(",", ":")) + "\n")
            self.send_response(200)
            self._cors()
            self.end_headers()

        def log_message(self, *args):
            pass

    return Handler


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", help="JSON-lines output file (appended)")
    ap.add_argument("--port", type=int, default=9000)
    a = ap.parse_args()
    try:
        server = http.server.HTTPServer(("127.0.0.1", a.port), make_handler(a.file))
    except OSError as e:  # a second listener on the same port would silently steal the results
        sys.exit(f"perf_listener: cannot listen on 127.0.0.1:{a.port} ({e}). Another listener probably holds it and would receive the page's results.")
    print(f"listening on 127.0.0.1:{a.port} -> {a.file}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
