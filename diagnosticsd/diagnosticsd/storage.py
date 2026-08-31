from __future__ import annotations

import csv
import fcntl
import os
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path


HISTORY_HEADER = (
    "timestamp", "cpu_percent", "ram_percent", "gpu_percent", "cpu_temp", "gpu_temp",
    "battery_charge", "battery_health", "battery_cycles", "disk_usage", "nvme_temp",
    "overall_health",
)


class CsvHistory:
    """Bounded history using locked, atomic whole-file replacement."""

    def __init__(self, path: Path, max_age_days: int = 30, max_rows: int = 50_000):
        self.path = path
        self.lock_path = path.with_suffix(path.suffix + ".lock")
        self.max_age = timedelta(days=max_age_days)
        self.max_rows = max_rows
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self._replace([])

    def append(self, values: dict, now: datetime | None = None) -> None:
        timestamp = now or datetime.now(timezone.utc)
        row = {column: "" for column in HISTORY_HEADER}
        row.update({key: value for key, value in values.items() if key in row and value is not None})
        row["timestamp"] = timestamp.isoformat(timespec="seconds")

        self.lock_path.touch(mode=0o600, exist_ok=True)
        with self.lock_path.open("r+") as lock:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
            cutoff = timestamp - self.max_age
            rows = [existing for existing in self.read() if self._timestamp(existing) >= cutoff]
            rows.append(row)
            self._replace(rows[-self.max_rows:])
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)

    def read(self, limit: int | None = None) -> list[dict]:
        try:
            with self.path.open(newline="") as handle:
                rows = list(csv.DictReader(handle))
        except (FileNotFoundError, csv.Error):
            return []
        return rows[-limit:] if limit is not None else rows

    @staticmethod
    def _timestamp(row: dict) -> datetime:
        try:
            value = datetime.fromisoformat(row["timestamp"])
            return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
        except (KeyError, TypeError, ValueError):
            return datetime.min.replace(tzinfo=timezone.utc)

    def _replace(self, rows: list[dict]) -> None:
        descriptor, temporary = tempfile.mkstemp(prefix=".history-", suffix=".csv", dir=self.path.parent)
        try:
            with os.fdopen(descriptor, "w", newline="") as handle:
                writer = csv.DictWriter(handle, fieldnames=HISTORY_HEADER, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(rows)
                handle.flush()
                os.fsync(handle.fileno())
            os.chmod(temporary, 0o600)
            os.replace(temporary, self.path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
