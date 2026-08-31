from __future__ import annotations

import argparse
import logging
import os
import shutil
from pathlib import Path

from .api import DiagnosticsServer
from .service import DiagnosticsService, install_signal_handlers


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read-only local system diagnostics daemon")
    parser.add_argument("--config", type=Path, default=Path.home() / ".config/diagnosticsd/thresholds.toml")
    parser.add_argument("--history", type=Path, default=Path.home() / ".local/share/diagnosticsd/history.csv")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=17373)
    return parser.parse_args()


def ensure_unprivileged() -> None:
    if os.geteuid() == 0:
        raise SystemExit("diagnosticsd refuses to run as root")


def ensure_config(path: Path) -> None:
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    packaged = Path(__file__).resolve().parents[1] / "thresholds.toml"
    temporary = path.with_suffix(".toml.tmp")
    shutil.copyfile(packaged, temporary)
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)


def main() -> None:
    ensure_unprivileged()
    args = parse_args()
    ensure_config(args.config)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    service = DiagnosticsService(args.config, args.history)
    server = DiagnosticsServer((args.host, args.port), service)
    install_signal_handlers(service, server.shutdown)
    service.start()
    try:
        server.serve_forever(poll_interval=0.5)
    finally:
        service.stop()
        server.server_close()


if __name__ == "__main__":
    main()
