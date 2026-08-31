from __future__ import annotations

from dataclasses import dataclass

from .config import ThresholdConfig
from .model import CATEGORIES, Evaluation, Finding, Metric

DEBOUNCE = {"fast": 3, "medium": 2, "slow": 1}
SCORES = {"OK": 100, "WARNING": 70, "CRITICAL": 20}


@dataclass
class PendingState:
    confirmed: str = "UNKNOWN"
    pending: str | None = None
    count: int = 0


class DiagnosticEngine:
    def __init__(self, config: ThresholdConfig):
        self.config = config
        self.states: dict[str, PendingState] = {}
        self.evaluations: dict[str, Evaluation] = {}
        self.metrics: dict[str, Metric] = {}
        self.active_findings: dict[str, dict] = {}

    @staticmethod
    def key(metric: Metric) -> str:
        return f"{metric.category}.{metric.name}"

    def evaluate(self, metric: Metric) -> Evaluation:
        if not metric.available or metric.value is None:
            return Evaluation("UNKNOWN", "data available", metric.detail or "metric is unavailable")
        rule = self.config.rule(metric.category, metric.name)
        if not rule or rule.get("diagnostic", True) is False:
            return Evaluation("OK", "informational", "informational metric")

        direction = rule.get("direction", "high")
        warning = float(rule["warning"])
        critical = float(rule["critical"])
        value = metric.value
        if direction == "low":
            severity = "CRITICAL" if value <= critical else "WARNING" if value <= warning else "OK"
            expected = f"> {warning:g}{metric.unit}"
        else:
            severity = "CRITICAL" if value >= critical else "WARNING" if value >= warning else "OK"
            expected = f"< {warning:g}{metric.unit}"
        reason = str(rule.get(f"{severity.lower()}_reason", rule.get("reason", f"{metric.name.replace('_', ' ')} is {severity.lower()}")))
        return Evaluation(severity, expected, reason)

    def observe(self, metric: Metric) -> Finding | None:
        key = self.key(metric)
        evaluation = self.evaluate(metric)
        state = self.states.setdefault(key, PendingState())
        self.metrics[key] = metric
        self.evaluations[key] = evaluation

        if evaluation.severity == state.confirmed:
            if key in self.active_findings:
                self.active_findings[key]["value"] = metric.value
                self.active_findings[key]["last_seen"] = metric.ts
            state.pending = None
            state.count = 0
            return None
        if evaluation.severity != state.pending:
            state.pending = evaluation.severity
            state.count = 1
        else:
            state.count += 1
        if state.count < DEBOUNCE[metric.tier]:
            return None

        state.confirmed = evaluation.severity
        state.pending = None
        state.count = 0
        finding = Finding(
            id=key.upper().replace(".", "-"), category=metric.category, metric=metric.name,
            severity=evaluation.severity, value=metric.value, unit=metric.unit,
            expected=evaluation.expected, reason=evaluation.reason, ts=metric.ts,
        )
        if evaluation.severity in {"WARNING", "CRITICAL"}:
            first_seen = self.active_findings.get(key, {}).get("first_seen", metric.ts)
            self.active_findings[key] = {
                **finding.to_dict(), "first_seen": first_seen, "last_seen": metric.ts, "resolved_at": None,
            }
        else:
            self.active_findings.pop(key, None)
        return finding

    def findings(self) -> list[dict]:
        rank = {"CRITICAL": 0, "WARNING": 1}
        return sorted(
            (dict(value) for value in self.active_findings.values()),
            key=lambda value: (rank.get(value["severity"], 2), -value["last_seen"]),
        )

    def category_states(self) -> dict[str, str]:
        result = {category: "UNKNOWN" for category in CATEGORIES}
        rank = {"UNKNOWN": -1, "OK": 0, "WARNING": 1, "CRITICAL": 2}
        for key, state in self.states.items():
            category = key.split(".", 1)[0]
            if state.confirmed == "UNKNOWN":
                continue
            if result[category] == "UNKNOWN" or rank[state.confirmed] > rank[result[category]]:
                result[category] = state.confirmed
        return result

    def health(self) -> dict:
        categories = self.category_states()
        known = [SCORES[value] for value in categories.values() if value in SCORES]
        complete = all(value != "UNKNOWN" for value in categories.values())
        return {
            "overall_pct": round(sum(known) / len(known)) if complete and known else None,
            "complete": complete,
            "categories": categories,
        }
