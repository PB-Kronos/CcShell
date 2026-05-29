from __future__ import annotations

import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for parent in current.parents:
        if parent.name == "computer":
            return parent.parent
    return current.parents[3]


REPO_ROOT = resolve_repo_root()
PY_ROOT = REPO_ROOT / "python"
EXECBRIDGE_URL = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/source/py/execbridge.py"
pending = None


def send(msg: str):
    global pending
    pending = msg


def receive(msg: str):
    parts = msg.strip().split()
    if not parts:
        return

    if parts[0] == "install":
        print("[INSTALL] preparing python bridge")
        print(f"[INSTALL] repo root: {REPO_ROOT}")
        print(f"[INSTALL] python root: {PY_ROOT}")
        PY_ROOT.mkdir(parents=True, exist_ok=True)
        print("[INSTALL] downloading execbridge.py")
        with urllib.request.urlopen(EXECBRIDGE_URL) as response:
            (PY_ROOT / "execbridge.py").write_bytes(response.read())
        print("[INSTALL] bridge installed")
        send("ok")
    else:
        send("unknown command")


class Handler(BaseHTTPRequestHandler):
    def _send(self, text: str):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(text.encode())

    def do_GET(self):
        global pending
        if self.path == "/input":
            msg = pending if pending else ""
            pending = None
            self._send(msg)
        else:
            self.send_error(404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(length).decode()
        if self.path == "/output":
            receive(data)
            self._send("ok")
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        return


HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
