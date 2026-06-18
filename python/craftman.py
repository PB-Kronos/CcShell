from __future__ import annotations

from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
WEB_ROOT = HERE.parent / "computer" / "0" / "var" / "craftman"
PORT = 8010


class Handler(SimpleHTTPRequestHandler):
    server_version = "CraftMan/1.0"

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(204)
        self.end_headers()

    def log_message(self, format: str, *args: object) -> None:  # noqa: A003
        return


def main() -> None:
    handler = partial(Handler, directory=str(WEB_ROOT))
    server = ThreadingHTTPServer(("0.0.0.0", PORT), handler)
    print(f"CraftMan static server listening on http://0.0.0.0:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
