from __future__ import annotations

from dataclasses import asdict, dataclass
from time import time


SEVERITIES = ("OK", "WARNING", "CRITICAL", "UNKNOWN")
CATEGORIES = ("cpu", "gpu", "ram", "storage", "battery", "thermal", "network", "kernel")


@dataclass(frozen=True)
class Metric:
    category: str
    name: str
    value: float | None
    unit: str
    tier: str
    source: str
    ts: float = 0
    available: bool = True
    detail: str = ""

    def __post_init__(self) -> None:
        if not self.ts:
            object.__setattr__(self, "ts", time())


@dataclass(frozen=True)
class Evaluation:
    severity: str
    expected: str
    reason: str


@dataclass(frozen=True)
class Finding:
    id: str
    category: str
    metric: str
    severity: str
    value: float | None
    unit: str
    expected: str
    reason: str
    ts: float

    def to_dict(self) -> dict:
        return asdict(self)
