from __future__ import annotations

import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import ctypes


HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

try:
    import bridgefs
except ModuleNotFoundError:
    bridgefs = None

pending = None
CRAFTOS_ROOT = Path(os.path.expandvars(r"%APPDATA%")) / "CraftOS-PC"
_taskbar_hidden = False

user32 = None
try:
    user32 = ctypes.windll.user32
except Exception:
    user32 = None


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
    if user32 is None:
        raise RuntimeError("Windows user32 API is unavailable")
    user32.LockWorkStation()


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


def _find_taskbar_handle():
    if user32 is None:
        return None
    return user32.FindWindowW("Shell_TrayWnd", None)


def taskbar_hidden():
    handle = _find_taskbar_handle()
    if not handle:
        return False
    return not bool(user32.IsWindowVisible(handle))


def taskbar_show():
    global _taskbar_hidden
    handle = _find_taskbar_handle()
    if not handle:
        raise RuntimeError("taskbar window not found")
    user32.ShowWindow(handle, 5)
    _taskbar_hidden = False
    return "taskbar shown"


def taskbar_hide():
    global _taskbar_hidden
    handle = _find_taskbar_handle()
    if not handle:
        raise RuntimeError("taskbar window not found")
    user32.ShowWindow(handle, 0)
    _taskbar_hidden = True
    return "taskbar hidden"


def taskbar_toggle():
    if taskbar_hidden():
        return taskbar_show()
    return taskbar_hide()


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
    elif cmd == "install":
        send("Already Installed")
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
    elif cmd == "taskbar":
        try:
            action = args[0] if args else "status"
            if action == "hide":
                send(taskbar_hide())
            elif action == "show":
                send(taskbar_show())
            elif action == "toggle":
                send(taskbar_toggle())
            elif action == "status":
                send("hidden" if taskbar_hidden() else "visible")
            else:
                send("unknown taskbar action: " + action)
        except Exception as e:
            send(f"taskbar error: {str(e)}")
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
