#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load_contract(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify an ordered Linux boot diagnostic sequence.")
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
    evidence: list[dict[str, object]] = []

    lower_text = text.lower()
    for pattern in contract["fatal_patterns"]:
        if pattern.lower() in lower_text:
            failures.append(f"fatal boot pattern present: {pattern}")

    cursor = -1
    for stage in contract["sequence"]:
        marker = stage["marker"]
        position = text.find(marker, cursor + 1)
        ok = position >= 0
        if not ok:
            failures.append(f"missing or out-of-order stage {stage['id']}: {marker}")
        else:
            cursor = position
        evidence.append(
            {
                "id": stage["id"],
                "description": stage["description"],
                "marker": marker,
                "ok": ok,
                "offset": position,
            }
        )

    report = {
        "schema": contract.get("schema", 1),
        "log": str(args.log),
        "ok": not failures,
        "stages": evidence,
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
