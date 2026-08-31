import tempfile
import unittest
from pathlib import Path

from unittest.mock import patch

from diagnosticsd.collectors import BatteryCollector, KernelCollector, NetworkCollector


class BatteryCollectorTests(unittest.TestCase):
    def test_health_uses_full_over_design_not_charge(self):
        with tempfile.TemporaryDirectory() as directory:
            battery = Path(directory) / "BAT0"
            battery.mkdir()
            (battery / "capacity").write_text("95\n")
            (battery / "energy_full").write_text("84200\n")
            (battery / "energy_full_design").write_text("100000\n")
            metrics = {metric.name: metric for metric in BatteryCollector(Path(directory)).collect()}
            self.assertEqual(metrics["charge"].value, 95)
            self.assertEqual(metrics["health"].value, 84.2)

    def test_missing_battery_returns_unknown(self):
        with tempfile.TemporaryDirectory() as directory:
            metric = BatteryCollector(Path(directory)).collect_safe()[0]
            self.assertFalse(metric.available)
            self.assertEqual(metric.category, "battery")

    @patch("diagnosticsd.collectors.subprocess.run")
    def test_network_reports_default_route_interface(self, run):
        run.side_effect = [
            type("Result", (), {"stdout": "default via 192.168.1.1 dev wlan0\n", "returncode": 0})(),
            type("Result", (), {"stdout": "2: wlan0: <BROADCAST> state UP\n", "returncode": 0})(),
        ]
        metrics = NetworkCollector().collect()
        self.assertEqual(metrics[0].name, "link_state")
        self.assertEqual(metrics[0].value, 1)

    @patch("diagnosticsd.collectors.subprocess.run")
    def test_kernel_counts_failed_units(self, run):
        run.side_effect = [
            type("Result", (), {"stdout": "6.1.0-arch1\n", "returncode": 0})(),
            type("Result", (), {"stdout": "bad.service loaded failed failed Broken\n", "returncode": 0})(),
        ]
        metrics = KernelCollector().collect()
        self.assertEqual(metrics[0].name, "failed_units")
        self.assertEqual(metrics[0].value, 1)


if __name__ == "__main__":
    unittest.main()
