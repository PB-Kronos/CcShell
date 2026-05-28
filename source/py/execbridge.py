from __future__ import annotations

import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

try:
    import bridgefs
except ModuleNotFoundError:
    bridgefs = None

pending = None
CRAFTOS_ROOT = Path(os.path.expandvars(r"%APPDATA%")) / "CraftOS-PC"


def open_explorer(path=None):
    if path:
        subprocess.Popen(f'explorer "{path}"')
    else:
        subprocess.Popen("explorer.exe")


def shutdown_windows():
    os.system("shutdown /s /t 0")


def restart_windows():
    os.system("shutdown /r /t 0")


def lock_windows():
    import ctypes

    ctypes.windll.user32.LockWorkStation()


def run_program(path):
    subprocess.Popen(path)


def run_exec(command: str):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        output = (result.stdout or result.stderr or "").strip()
        if len(output) > 2000:
            output = output[:2000] + "\n...[TRUNCATED]"
        send(output if output else "ok")
    except Exception as e:
        send(f"exec error: {str(e)}")


def run_execwait(command: str):
    try:
        subprocess.run(f"start cmd /k {command}", shell=True)
        send("execwait started")
    except Exception as e:
        send(f"execwait error: {str(e)}")


def send(msg: str):
    global pending
    pending = msg
    print("[SEND TO CC]", msg)


def receive(msg: str):
    handle_message(msg)


def repo_download(src: str, dst: str):
    import urllib.request

    raw = dst.replace("\\", "/")
    target = (CRAFTOS_ROOT / raw.lstrip("/")).resolve()
    target_root = CRAFTOS_ROOT.resolve()
    if not str(target).startswith(str(target_root)):
        raise ValueError("download destination must stay within CraftOS-PC")

    url = src if src.startswith(("http://", "https://")) else f"https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main/{src.lstrip('/')}"
    target.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        target.write_bytes(response.read())


def handle_message(msg):
    print("[FROM CC]", msg)
    parts = msg.strip().split()
    if not parts:
        return

    cmd = parts[0]
    args = parts[1:]

    if cmd == "ping":
        send("pong")
    elif cmd == "print":
        send(" ".join(args))
    elif cmd == "explorer":
        open_explorer(" ".join(args) if args else None)
    elif cmd == "shutdown":
        shutdown_windows()
    elif cmd == "restart":
        restart_windows()
    elif cmd == "lock":
        lock_windows()
    elif cmd == "run":
        run_program(" ".join(args))
    elif cmd == "start":
        subprocess.Popen(f'start "" {" ".join(args)}', shell=True)
    elif cmd == "exec":
        run_exec(" ".join(args))
    elif cmd == "execwait":
        run_execwait(" ".join(args))
    elif cmd == "download":
        if bridgefs and hasattr(bridgefs, "download"):
            try:
                bridgefs.download(args[0], args[1])
                send("ok")
            except Exception as e:
                send(f"download error: {str(e)}")
        else:
            try:
                repo_download(args[0], args[1])
                send("ok")
            except Exception as e:
                send(f"download error: {str(e)}")
    else:
        send("unknown command: " + cmd)


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
            print("[WARN] Unknown GET:", self.path)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(length).decode()
        if self.path == "/output":
            receive(data)
            self._send("ok")
        else:
            self.send_error(404)
            print("[WARN] Unknown POST:", self.path, data)

    def log_message(self, format, *args):
        return


HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
