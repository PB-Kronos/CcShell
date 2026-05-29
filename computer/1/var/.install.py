from __future__ import annotations

import shutil
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SRC_PY = Path(__file__).resolve().parent
PY_ROOT = REPO_ROOT / "python"
pending = None


def send(msg: str):
    global pending
    pending = msg


def receive(msg: str):
    parts = msg.strip().split()
    if not parts:
        return

    if parts[0] == "install":
        PY_ROOT.mkdir(parents=True, exist_ok=True)
        shutil.copy2(SRC_PY / "execbridge.py", PY_ROOT / "execbridge.py")
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
