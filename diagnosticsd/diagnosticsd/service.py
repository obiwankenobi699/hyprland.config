from __future__ import annotations

import logging
import shutil
import signal
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

from .collectors import Collector, phase_one_collectors
from .config import ThresholdConfig
from .engine import DiagnosticEngine
from .storage import CsvHistory

LOG = logging.getLogger(__name__)
OPTIONAL_BINARIES = ("smartctl", "nvidia-smi", "sensors", "journalctl", "ss", "ip", "ethtool", "upower", "systemctl", "uname")


class DiagnosticsService:
    def __init__(self, config_path: Path, history_path: Path, collectors: list[Collector] | None = None,
                 history_interval_s: int = 60):
        self.config = ThresholdConfig(config_path)
        self.engine = DiagnosticEngine(self.config)
        self.history = CsvHistory(history_path)
        self.collectors = collectors if collectors is not None else phase_one_collectors()
        self.missing_dependencies = [name for name in OPTIONAL_BINARIES if shutil.which(name) is None]
        self.last_updated: float | None = None
        self._stop = threading.Event()
        self._state_lock = threading.RLock()
        self._threads: list[threading.Thread] = []
        self.history_interval_s = history_interval_s

    def start(self) -> None:
        for collector in self.collectors:
            thread = threading.Thread(target=self._collector_loop, args=(collector,), daemon=True, name=collector.name)
            thread.start()
            self._threads.append(thread)
        history_thread = threading.Thread(target=self._history_loop, daemon=True, name="history")
        history_thread.start()
        self._threads.append(history_thread)

    def stop(self) -> None:
        self._stop.set()

    def reload(self) -> None:
        with self._state_lock:
            self.config.reload()
        LOG.info("reloaded thresholds from %s", self.config.path)

    def _collector_loop(self, collector: Collector) -> None:
        while not self._stop.is_set():
            started = time.monotonic()
            for metric in collector.collect_safe():
                with self._state_lock:
                    self.engine.observe(metric)
                    self.last_updated = time.time()
            elapsed = time.monotonic() - started
            self._stop.wait(max(0.1, collector.poll_interval_s - elapsed))

    def _history_loop(self) -> None:
        # Wait for initial collector debounce before recording the first snapshot.
        while not self._stop.wait(self.history_interval_s):
            self.record_history()

    def record_history(self) -> None:
        metric_columns = {
            "cpu_percent": "cpu.usage", "ram_percent": "ram.usage",
            "gpu_percent": "gpu.usage", "cpu_temp": "thermal.cpu_temperature",
            "gpu_temp": "thermal.gpu_temperature", "battery_charge": "battery.charge",
            "battery_health": "battery.health", "battery_cycles": "battery.cycles",
            "disk_usage": "storage.disk_usage", "nvme_temp": "storage.nvme_temperature",
        }
        with self._state_lock:
            health = self.engine.health()
            values = {
                column: self.engine.metrics[key].value
                for column, key in metric_columns.items() if key in self.engine.metrics
            }
            values["overall_health"] = health["overall_pct"]
        self.history.append(values, datetime.now(timezone.utc))

    def health_payload(self) -> dict:
        with self._state_lock:
            payload = self.engine.health()
            payload.update({
                "last_updated": self.last_updated,
                "missing_dependencies": self.missing_dependencies,
                "metrics": {
                    key: {
                        "value": metric.value, "unit": metric.unit, "available": metric.available,
                        "detail": metric.detail, "severity": self.engine.evaluations[key].severity,
                        "expected": self.engine.evaluations[key].expected,
                    }
                    for key, metric in self.engine.metrics.items()
                },
            })
        return payload

    def findings_payload(self) -> list[dict]:
        with self._state_lock:
            return self.engine.findings()

    def history_payload(self, limit: int = 1440) -> list[dict]:
        return self.history.read(max(1, min(limit, 50_000)))


def install_signal_handlers(service: DiagnosticsService, shutdown=None) -> None:
    signal.signal(signal.SIGHUP, lambda *_: service.reload())

    def stop(*_) -> None:
        service.stop()
        if shutdown is not None:
            # BaseServer.shutdown must run outside the serve_forever thread.
            threading.Thread(target=shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
