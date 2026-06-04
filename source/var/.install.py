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
SOURCE_PY_ROOT = REPO_ROOT / "source" / "py"
GITHUB_RAW_BASE = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main"
pending = None


def send(msg: str):
    global pending
    pending = msg


def _repo_raw_url(path: str) -> str:
    return f"{GITHUB_RAW_BASE}/{path.lstrip('/')}"


def _install_python_tree():
    print("[INSTALL] preparing python tree")
    print(f"[INSTALL] repo root: {REPO_ROOT}")
    print(f"[INSTALL] python root: {PY_ROOT}")
    PY_ROOT.mkdir(parents=True, exist_ok=True)

    for source_file in sorted(SOURCE_PY_ROOT.glob("*.py")):
        target = PY_ROOT / source_file.name
        print(f"[INSTALL] downloading {source_file.name}")
        with urllib.request.urlopen(_repo_raw_url(f"source/py/{source_file.name}")) as response:
            target.write_bytes(response.read())

    print("[INSTALL] python tree installed")


def _cleanup_self():
    try:
        Path(__file__).resolve().unlink(missing_ok=True)
        print("[INSTALL] staged installer removed")
    except Exception as exc:
        print(f"[INSTALL] cleanup skipped: {exc}")


def receive(msg: str):
    parts = msg.strip().split()
    if not parts:
        return

    if parts[0] == "install":
        _install_python_tree()
        _cleanup_self()
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
