from __future__ import annotations

import tomllib
from pathlib import Path


class ThresholdConfig:
    def __init__(self, path: Path):
        self.path = path
        self.data: dict = {}
        self.reload()

    def reload(self) -> None:
        with self.path.open("rb") as handle:
            self.data = tomllib.load(handle)

    def rule(self, category: str, metric: str) -> dict | None:
        value = self.data.get(category, {}).get(metric)
        return value if isinstance(value, dict) else None
