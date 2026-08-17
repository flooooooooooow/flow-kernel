#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare a system-health report with a known-good baseline.")
    parser.add_argument("current", type=Path)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--warn-ratio", type=float, default=1.5)
    parser.add_argument("--fail-ratio", type=float, default=3.0)
    parser.add_argument("--slack-ms", type=int, default=250)
    args = parser.parse_args()

    current = load(args.current)
    baseline = load(args.baseline)
    current_stages = {stage["id"]: stage for stage in current.get("stages", [])}
    baseline_stages = {stage["id"]: stage for stage in baseline.get("stages", [])}

    failures: list[str] = []
    warnings: list[str] = []
    timing: list[dict[str, object]] = []

    if not current.get("ok", False):
        failures.append("current health report is not healthy")

    for stage_id, old in baseline_stages.items():
        new = current_stages.get(stage_id)
        if new is None:
            failures.append(f"stage disappeared: {stage_id}")
            continue
        if old.get("ok") and not new.get("ok"):
            failures.append(f"previously healthy stage regressed: {stage_id}")

        old_ms = old.get("time_ms")
        new_ms = new.get("time_ms")
        if not isinstance(old_ms, int) or not isinstance(new_ms, int) or old_ms <= 0:
            continue

        allowed_warn = int(old_ms * args.warn_ratio) + args.slack_ms
        allowed_fail = int(old_ms * args.fail_ratio) + args.slack_ms
        level = "ok"
        if new_ms > allowed_fail:
            level = "fail"
            failures.append(f"timing regression at {stage_id}: {new_ms}ms vs {old_ms}ms baseline")
        elif new_ms > allowed_warn:
            level = "warn"
            warnings.append(f"timing regression at {stage_id}: {new_ms}ms vs {old_ms}ms baseline")
        timing.append({"id": stage_id, "baseline_ms": old_ms, "current_ms": new_ms, "level": level})

    result = {
        "schema": 1,
        "ok": not failures,
        "current": str(args.current),
        "baseline": str(args.baseline),
        "failures": failures,
        "warnings": warnings,
        "timing": timing,
    }

    rendered = json.dumps(result, indent=2)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
