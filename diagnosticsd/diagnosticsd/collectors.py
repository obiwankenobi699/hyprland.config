from __future__ import annotations

import logging
import os
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor, TimeoutError
from pathlib import Path
from time import sleep

from .model import Metric

LOG = logging.getLogger(__name__)


class Collector:
    name = "collector"
    category = "unknown"
    poll_interval_s = 30
    timeout_s = 2
    tier = "medium"
    optional_binaries: tuple[str, ...] = ()

    def is_available(self) -> bool:
        return True

    def collect(self) -> list[Metric]:
        raise NotImplementedError

    def collect_safe(self) -> list[Metric]:
        if not self.is_available():
            return [self.unknown("required system interface is unavailable")]
        executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix=self.name)
        future = executor.submit(self.collect)
        try:
            return future.result(timeout=self.timeout_s)
        except TimeoutError:
            future.cancel()
            LOG.warning("collector %s timed out after %ss", self.name, self.timeout_s)
            return [self.unknown(f"collector timed out after {self.timeout_s}s")]
        except Exception as error:  # collector isolation is intentional
            LOG.exception("collector %s failed", self.name)
            return [self.unknown(str(error))]
        finally:
            executor.shutdown(wait=False, cancel_futures=True)

    def metric(self, name: str, value: float, unit: str, source: str, detail: str = "") -> Metric:
        return Metric(self.category, name, value, unit, self.tier, source, detail=detail)

    def unknown(self, detail: str) -> Metric:
        return Metric(self.category, self.name, None, "", self.tier, self.name, available=False, detail=detail)


class CpuCollector(Collector):
    name = "cpu_usage"
    category = "cpu"
    poll_interval_s = 2
    timeout_s = 1
    tier = "fast"

    def __init__(self, proc_root: Path = Path("/proc")):
        self.proc_root = proc_root

    def is_available(self) -> bool:
        return (self.proc_root / "stat").is_file()

    def _sample(self) -> tuple[int, int]:
        fields = (self.proc_root / "stat").read_text().splitlines()[0].split()[1:]
        values = [int(value) for value in fields]
        idle = values[3] + (values[4] if len(values) > 4 else 0)
        return sum(values), idle

    def collect(self) -> list[Metric]:
        total1, idle1 = self._sample()
        sleep(0.2)
        total2, idle2 = self._sample()
        delta = total2 - total1
        usage = 0 if delta <= 0 else 100 * (delta - (idle2 - idle1)) / delta
        return [self.metric("usage", round(usage, 1), "%", "/proc/stat")]


class RamCollector(Collector):
    name = "ram_usage"
    category = "ram"
    poll_interval_s = 2
    timeout_s = 1
    tier = "fast"

    def __init__(self, proc_root: Path = Path("/proc")):
        self.path = proc_root / "meminfo"

    def is_available(self) -> bool:
        return self.path.is_file()

    def collect(self) -> list[Metric]:
        values = {}
        for line in self.path.read_text().splitlines():
            key, value = line.split(":", 1)
            values[key] = int(value.split()[0])
        used = 100 * (values["MemTotal"] - values["MemAvailable"]) / values["MemTotal"]
        return [self.metric("usage", round(used, 1), "%", "/proc/meminfo")]


class DiskUsageCollector(Collector):
    name = "disk_usage"
    category = "storage"
    poll_interval_s = 30
    timeout_s = 1
    tier = "medium"

    def __init__(self, path: Path = Path("/")):
        self.path = path

    def collect(self) -> list[Metric]:
        usage = os.statvfs(self.path)
        total = usage.f_blocks * usage.f_frsize
        available = usage.f_bavail * usage.f_frsize
        percent = 100 * (total - available) / total
        return [self.metric("disk_usage", round(percent, 1), "%", f"statvfs:{self.path}")]


class BatteryCollector(Collector):
    name = "battery"
    category = "battery"
    poll_interval_s = 30
    timeout_s = 1
    tier = "medium"

    def __init__(self, power_root: Path = Path("/sys/class/power_supply")):
        self.power_root = power_root

    def _battery(self) -> Path | None:
        candidates = sorted(self.power_root.glob("BAT*"))
        return candidates[0] if candidates else None

    def is_available(self) -> bool:
        return self._battery() is not None

    @staticmethod
    def _read_number(path: Path) -> float | None:
        try:
            return float(path.read_text().strip())
        except (OSError, ValueError):
            return None

    def collect(self) -> list[Metric]:
        battery = self._battery()
        if battery is None:
            return [self.unknown("battery was not found")]
        metrics = []
        charge = self._read_number(battery / "capacity")
        if charge is not None:
            metrics.append(self.metric("charge", charge, "%", str(battery / "capacity")))

        full = self._read_number(battery / "energy_full") or self._read_number(battery / "charge_full")
        design = self._read_number(battery / "energy_full_design") or self._read_number(battery / "charge_full_design")
        if full is not None and design:
            metrics.append(self.metric("health", round(100 * full / design, 1), "%", "battery full/design capacity"))
        else:
            metrics.append(Metric(self.category, "health", None, "%", self.tier, "battery full/design capacity", available=False, detail="full or design capacity is unavailable"))

        # Generic kernel interface is deliberately checked before any vendor fallback.
        for name in ("charge_control_start_threshold", "charge_control_end_threshold"):
            value = self._read_number(battery / name)
            if value is not None:
                metrics.append(self.metric(name.removeprefix("charge_control_"), value, "%", str(battery / name)))
        return metrics


class ThermalCollector(Collector):
    name = "temperature"
    category = "thermal"
    poll_interval_s = 2
    timeout_s = 1
    tier = "fast"

    def __init__(self, hwmon_root: Path = Path("/sys/class/hwmon")):
        self.hwmon_root = hwmon_root

    def is_available(self) -> bool:
        return self.hwmon_root.is_dir()

    def collect(self) -> list[Metric]:
        readings = []
        for directory in self.hwmon_root.glob("hwmon*"):
            try:
                device = (directory / "name").read_text().strip()
            except OSError:
                continue
            if device not in {"coretemp", "k10temp", "zenpower"}:
                continue
            for path in directory.glob("temp*_input"):
                try:
                    readings.append(float(path.read_text().strip()) / 1000)
                except (OSError, ValueError):
                    continue
        if not readings:
            return [self.unknown("CPU temperature sensor is unavailable")]
        return [self.metric("cpu_temperature", round(max(readings), 1), "°C", "/sys/class/hwmon")]


class NetworkCollector(Collector):
    name = "default_route"
    category = "network"
    poll_interval_s = 30
    timeout_s = 2
    tier = "medium"
    optional_binaries = ("ip",)

    def is_available(self) -> bool:
        return shutil.which("ip") is not None

    def collect(self) -> list[Metric]:
        route = subprocess.run(
            ["ip", "-4", "route", "show", "default"],
            capture_output=True, text=True, timeout=self.timeout_s, check=False,
        )
        line = route.stdout.strip().splitlines()[0] if route.stdout.strip() else ""
        fields = line.split()
        interface = fields[fields.index("dev") + 1] if "dev" in fields else ""
        if not interface:
            return [self.unknown("no default network route is available")]

        link = subprocess.run(
            ["ip", "-o", "link", "show", "dev", interface],
            capture_output=True, text=True, timeout=self.timeout_s, check=False,
        )
        is_up = "state UP" in link.stdout
        return [self.metric("link_state", 1 if is_up else 0, "state", f"ip:{interface}",
                            detail=f"default route via {interface}")]


class KernelCollector(Collector):
    name = "failed_units"
    category = "kernel"
    poll_interval_s = 30
    timeout_s = 2
    tier = "medium"
    optional_binaries = ("systemctl", "uname")

    def is_available(self) -> bool:
        return shutil.which("systemctl") is not None and shutil.which("uname") is not None

    def collect(self) -> list[Metric]:
        version = subprocess.run(
            ["uname", "-r"], capture_output=True, text=True, timeout=self.timeout_s, check=False,
        ).stdout.strip()
        failed = subprocess.run(
            ["systemctl", "--failed", "--no-legend", "--plain", "--no-pager"],
            capture_output=True, text=True, timeout=self.timeout_s, check=False,
        )
        if failed.returncode != 0:
            return [self.unknown("systemd failed-unit status is unavailable")]
        count = len([line for line in failed.stdout.splitlines() if line.strip()])
        return [
            self.metric("failed_units", count, " units", "systemctl --failed"),
            self.metric("version", 0, "", "uname -r", detail=version or "kernel version unavailable"),
        ]


def phase_one_collectors() -> list[Collector]:
    return [
        CpuCollector(), RamCollector(), DiskUsageCollector(), BatteryCollector(), ThermalCollector(),
        NetworkCollector(), KernelCollector(),
    ]
