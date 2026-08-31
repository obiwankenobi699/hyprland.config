import csv
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

from diagnosticsd.storage import HISTORY_HEADER, CsvHistory


class CsvHistoryTests(unittest.TestCase):
    def test_creates_stable_header_and_empty_missing_values(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.csv"
            history = CsvHistory(path)
            history.append({"cpu_percent": 12.5})
            with path.open(newline="") as handle:
                rows = list(csv.DictReader(handle))
                self.assertEqual(tuple(rows[0]), HISTORY_HEADER)
                self.assertEqual(rows[0]["cpu_percent"], "12.5")
                self.assertEqual(rows[0]["gpu_percent"], "")

    def test_prunes_by_age_and_row_limit(self):
        with tempfile.TemporaryDirectory() as directory:
            history = CsvHistory(Path(directory) / "history.csv", max_age_days=30, max_rows=3)
            now = datetime.now(timezone.utc)
            history.append({"cpu_percent": 1}, now - timedelta(days=31))
            for value in range(4):
                history.append({"cpu_percent": value}, now + timedelta(seconds=value))
            rows = history.read()
            self.assertEqual(len(rows), 3)
            self.assertEqual([row["cpu_percent"] for row in rows], ["1", "2", "3"])


if __name__ == "__main__":
    unittest.main()
