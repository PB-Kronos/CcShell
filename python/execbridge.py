from __future__ import annotations

import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import ctypes
import ctypes.wintypes
import threading


HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

try:
    import bridgefs
except ModuleNotFoundError:
    bridgefs = None

pending = None
CRAFTOS_ROOT = Path(os.path.expandvars(r"%APPDATA%")) / "CraftOS-PC"
_taskbar_hidden = False
_windows_key_blocked = False
_keyboard_hook = None
_hook_thread = None
_hook_thread_id = 0
_hook_stop = threading.Event()

WH_KEYBOARD_LL = 13
WM_KEYDOWN = 0x0100
WM_SYSKEYDOWN = 0x0104
WM_QUIT = 0x0012
VK_LWIN = 0x5B
VK_RWIN = 0x5C
HC_ACTION = 0

ULONG_PTR = getattr(ctypes.wintypes, "ULONG_PTR", ctypes.c_void_p)
LRESULT = getattr(ctypes.wintypes, "LRESULT", ctypes.c_long)
WPARAM = getattr(ctypes.wintypes, "WPARAM", ctypes.c_size_t)
LPARAM = getattr(ctypes.wintypes, "LPARAM", ctypes.c_ssize_t)

class KBDLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [
        ("vkCode", ctypes.wintypes.DWORD),
        ("scanCode", ctypes.wintypes.DWORD),
        ("flags", ctypes.wintypes.DWORD),
        ("time", ctypes.wintypes.DWORD),
        ("dwExtraInfo", ULONG_PTR),
    ]

user32 = None
kernel32 = None
try:
    user32 = ctypes.windll.user32
    kernel32 = ctypes.windll.kernel32
except Exception:
    user32 = None
    kernel32 = None


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

    url = src if src.startswith(("http://", "https://")) else f"https://raw.githubusercontent.com/PB-Kronos/CcShell/main/{src.lstrip('/')}"
    target.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response:
        target.write_bytes(response.read())


def _find_taskbar_handle():
    if user32 is None:
        return None
    return user32.FindWindowW("Shell_TrayWnd", None)


HOOKPROC = ctypes.WINFUNCTYPE(LRESULT, ctypes.c_int, WPARAM, LPARAM)


def _keyboard_proc(nCode, wParam, lParam):
    if nCode == HC_ACTION and wParam in (WM_KEYDOWN, WM_SYSKEYDOWN):
        kb = ctypes.cast(lParam, ctypes.POINTER(KBDLLHOOKSTRUCT)).contents
        if kb.vkCode in (VK_LWIN, VK_RWIN):
            return 1
    return user32.CallNextHookEx(_keyboard_hook, nCode, wParam, lParam)


_keyboard_proc_ref = HOOKPROC(_keyboard_proc)


def _hook_loop():
    global _keyboard_hook, _hook_thread_id
    if user32 is None or kernel32 is None:
        return

    _hook_thread_id = kernel32.GetCurrentThreadId()
    _keyboard_hook = user32.SetWindowsHookExW(WH_KEYBOARD_LL, _keyboard_proc_ref, kernel32.GetModuleHandleW(None), 0)
    if not _keyboard_hook:
        _hook_thread_id = 0
        return

    msg = ctypes.wintypes.MSG()
    try:
        while not _hook_stop.is_set():
            rc = user32.GetMessageW(ctypes.byref(msg), None, 0, 0)
            if rc == 0 or rc == -1:
                break
            user32.TranslateMessage(ctypes.byref(msg))
            user32.DispatchMessageW(ctypes.byref(msg))
    finally:
        try:
            user32.UnhookWindowsHookEx(_keyboard_hook)
        except Exception:
            pass
        _keyboard_hook = None
        _hook_thread_id = 0


def _start_windows_key_block():
    global _windows_key_blocked, _hook_thread
    if _windows_key_blocked:
        return
    if user32 is None or kernel32 is None:
        raise RuntimeError("Windows user32 API is unavailable")
    _hook_stop.clear()
    _hook_thread = threading.Thread(target=_hook_loop, daemon=True)
    _hook_thread.start()
    _windows_key_blocked = True


def _stop_windows_key_block():
    global _windows_key_blocked
    if not _windows_key_blocked:
        return
    _hook_stop.set()
    if kernel32 is not None and _hook_thread_id:
        try:
            kernel32.PostThreadMessageW(_hook_thread_id, WM_QUIT, 0, 0)
        except Exception:
            pass
    _windows_key_blocked = False


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
    _stop_windows_key_block()
    _taskbar_hidden = False
    return "taskbar shown"


def taskbar_hide():
    global _taskbar_hidden
    handle = _find_taskbar_handle()
    if not handle:
        raise RuntimeError("taskbar window not found")
    user32.ShowWindow(handle, 0)
    _start_windows_key_block()
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
