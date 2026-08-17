#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

DIAG_RE = re.compile(
    r"FLOW_DIAG\s+(?P<seq>\d{3})\s+(?P<name>[A-Z0-9_]+)\s+"
    r"(?P<status>OK|WARN)\s+t_ms=(?P<time>\d+)"
)


def load_contract(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify ordered Linux boot/system-health diagnostics.")
    parser.add_argument("log", type=Path)
    parser.add_argument(
        "--contract",
        type=Path,
        default=Path(__file__).with_name("boot-sequence.json"),
    )
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    text = args.log.read_text(encoding="utf-8", errors="replace")
    contract = load_contract(args.contract)

    failures: list[str] = []
    degraded: list[str] = []
    stages: list[dict[str, object]] = []
    last_good: str | None = None

    lower_text = text.lower()
    for pattern in contract["fatal_patterns"]:
        if pattern.lower() in lower_text:
            failures.append(f"fatal boot pattern present: {pattern}")

    diag_matches = list(DIAG_RE.finditer(text))
    diag_by_key = {(m.group("seq"), m.group("name")): m for m in diag_matches}

    cursor = -1
    previous_time: int | None = None
    for stage in contract["sequence"]:
        severity = stage.get("severity", "required")
        status = "MISSING"
        position = -1
        time_ms: int | None = None

        if stage.get("kind") == "log":
            position = text.find(stage["marker"], cursor + 1)
            if position >= 0:
                status = "OK"
        else:
            match = diag_by_key.get((stage["seq"], stage["name"]))
            if match is not None:
                position = match.start()
                status = match.group("status")
                time_ms = int(match.group("time"))

        ordered = position >= 0 and position > cursor
        if position >= 0 and not ordered:
            status = "OUT_OF_ORDER"

        if ordered:
            cursor = position
            last_good = stage["id"]
            if time_ms is not None and previous_time is not None and time_ms < previous_time:
                failures.append(
                    f"non-monotonic diagnostic timing at {stage['id']}: {time_ms} < {previous_time}"
                )
            if time_ms is not None:
                previous_time = time_ms
        else:
            message = f"missing or out-of-order stage {stage['id']}"
            if severity == "required":
                failures.append(message)
            else:
                degraded.append(message)

        if status == "WARN":
            degraded.append(f"advisory stage degraded: {stage['id']}")
        elif status not in {"OK", "WARN"} and ordered and severity == "required":
            failures.append(f"required stage {stage['id']} ended with status {status}")

        stages.append(
            {
                "id": stage["id"],
                "description": stage["description"],
                "severity": severity,
                "status": status,
                "ok": ordered and status in {"OK", "WARN"},
                "degraded": status == "WARN",
                "offset": position,
                "time_ms": time_ms,
            }
        )

    summary_match = re.search(r"FLOW_DIAG SUMMARY HEALTHY t_ms=(\d+)", text)
    total_time_ms = int(summary_match.group(1)) if summary_match else None
    if not summary_match:
        failures.append("missing final HEALTHY summary marker")

    report = {
        "schema": contract.get("schema", 1),
        "log": str(args.log),
        "ok": not failures,
        "health": "healthy" if not failures and not degraded else ("degraded" if not failures else "failed"),
        "last_good_stage": last_good,
        "total_time_ms": total_time_ms,
        "stages": stages,
        "degraded": degraded,
        "failures": failures,
    }

    rendered = json.dumps(report, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(rendered + "\n", encoding="utf-8")

    print(rendered)
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
