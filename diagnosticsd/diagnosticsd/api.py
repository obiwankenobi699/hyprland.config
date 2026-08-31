from __future__ import annotations

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse
from urllib.parse import parse_qs


class DiagnosticsServer(ThreadingHTTPServer):
    allow_reuse_address = True

    def __init__(self, address: tuple[str, int], service):
        if address[0] not in {"127.0.0.1", "localhost"}:
            raise ValueError("diagnostics API must bind to localhost")
        self.service = service
        super().__init__(address, DiagnosticsHandler)


class DiagnosticsHandler(BaseHTTPRequestHandler):
    server: DiagnosticsServer

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path == "/health":
            self._json(200, self.server.service.health_payload())
        elif path == "/findings":
            self._json(200, {"findings": self.server.service.findings_payload()})
        elif path == "/history":
            try:
                limit = int(parse_qs(urlparse(self.path).query).get("limit", ["1440"])[0])
            except ValueError:
                limit = 1440
            self._json(200, {"history": self.server.service.history_payload(limit)})
        else:
            self._json(404, {"error": "not found"})

    def _json(self, status: int, value: dict) -> None:
        payload = json.dumps(value, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args) -> None:
        return
