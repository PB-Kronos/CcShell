from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess
import os
import ctypes
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import bridgefs

# -------------------------
# STATE
# -------------------------
pending = None  # Python → CraftOS buffer

# -------------------------
# WINDOWS ACTIONS
# -------------------------
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
    ctypes.windll.user32.LockWorkStation()

def run_program(path):
    subprocess.Popen(path)

def host_read(path):
    try:
        return bridgefs.read_text(path)
    except Exception as e:
        send(f"read error: {str(e)}")
        return ""

def host_write(path, data):
    try:
        bridgefs.write_text(path, data)
        send("ok")
    except Exception as e:
        send(f"write error: {str(e)}")

def host_exists(path):
    return "true" if bridgefs.exists(path) else "false"

def host_list(path):
    try:
        return "\n".join(bridgefs.list_dir(path))
    except Exception as e:
        send(f"list error: {str(e)}")
        return ""

# -------------------------
# EXEC SYSTEM
# -------------------------
def run_exec(command: str):
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True
        )

        output = (result.stdout or result.stderr or "").strip()

        if len(output) > 2000:
            output = output[:2000] + "\n...[TRUNCATED]"

        send(output if output else "ok")

    except Exception as e:
        send(f"exec error: {str(e)}")


def run_execwait(command: str):
    try:
        subprocess.run(
            f'start cmd /k {command}',
            shell=True
        )

        send("execwait started")

    except Exception as e:
        send(f"execwait error: {str(e)}")


# -------------------------
# CORE API
# -------------------------
def send(msg: str):
    global pending
    pending = msg
    print("[SEND TO CC]", msg)


def receive(msg: str):
    handle_message(msg)


# -------------------------
# COMMAND ROUTER
# -------------------------
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
    elif cmd == "read":
        send(host_read(" ".join(args)))
    elif cmd == "write":
        if len(args) >= 2:
            host_write(args[0], " ".join(args[1:]))
        else:
            send("usage: write <path> <data>")
    elif cmd == "exists":
        send(host_exists(" ".join(args)))
    elif cmd == "list":
        send(host_list(" ".join(args) if args else "/"))
    else:
        send("unknown command: " + cmd)


# -------------------------
# HTTP SERVER
# -------------------------
class Handler(BaseHTTPRequestHandler):

    def _send(self, text: str):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(text.encode())

    # Python → CraftOS
    def do_GET(self):
        global pending

        if self.path == "/input":
            msg = pending if pending else ""
            pending = None
            self._send(msg)

        else:
            self.send_error(404)
            print("[WARN] Unknown GET:", self.path)

    # CraftOS → Python
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


# -------------------------
# START SERVER
# -------------------------
HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
