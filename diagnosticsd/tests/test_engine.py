import tempfile
import unittest
from pathlib import Path

from diagnosticsd.config import ThresholdConfig
from diagnosticsd.engine import DiagnosticEngine
from diagnosticsd.model import Metric


CONFIG = """
[storage.disk_usage]
warning = 80
critical = 95
[battery.health]
direction = "low"
warning = 80
critical = 60
"""


class EngineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "thresholds.toml"
        path.write_text(CONFIG)
        self.engine = DiagnosticEngine(ThresholdConfig(path))

    def tearDown(self):
        self.temp.cleanup()

    def metric(self, value, tier="fast"):
        return Metric("storage", "disk_usage", value, "%", tier, "fixture")

    def test_disk_warning_requires_three_fast_polls(self):
        self.assertIsNone(self.engine.observe(self.metric(80)))
        self.assertIsNone(self.engine.observe(self.metric(81)))
        finding = self.engine.observe(self.metric(82))
        self.assertEqual(finding.severity, "WARNING")

    def test_disk_no_flap_hovering_at_threshold(self):
        for value in (81, 81, 81):
            self.engine.observe(self.metric(value))
        for value in (79, 81, 79, 81):
            self.assertIsNone(self.engine.observe(self.metric(value)))
        self.assertEqual(self.engine.category_states()["storage"], "WARNING")

    def test_battery_health_is_not_charge(self):
        metric = Metric("battery", "health", 72, "%", "slow", "full/design")
        self.assertEqual(self.engine.observe(metric).severity, "WARNING")

    def test_unknown_category_prevents_overall_score(self):
        for value in (20, 20, 20):
            self.engine.observe(self.metric(value))
        health = self.engine.health()
        self.assertIsNone(health["overall_pct"])
        self.assertFalse(health["complete"])


if __name__ == "__main__":
    unittest.main()
