#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class HealthToolTests(unittest.TestCase):
    def make_log(self, warn_dns: bool = True) -> str:
        contract = json.loads((ROOT / "boot-sequence.json").read_text())
        lines = ["Linux version 6.18.35-tinycore64", "Trying to unpack rootfs image as initramfs..."]
        tick = 100
        for stage in contract["sequence"]:
            if stage["kind"] != "diag":
                continue
            status = "WARN" if warn_dns and stage["id"] == "dns" else "OK"
            lines.append(f"FLOW_DIAG {stage['seq']} {stage['name']} {status} t_ms={tick}")
            tick += 100
        lines.extend([
            "FLOW_EVIDENCE cpu_count=1",
            "FLOW_EVIDENCE mem_total_kb=262144",
            f"FLOW_DIAG SUMMARY HEALTHY t_ms={tick}",
        ])
        return "\n".join(lines) + "\n"

    def run_checker(self, text: str) -> tuple[int, dict]:
        with tempfile.TemporaryDirectory() as td:
            log = Path(td) / "serial.log"
            report = Path(td) / "report.json"
            log.write_text(text)
            result = subprocess.run(
                [sys.executable, str(ROOT / "check_boot.py"), str(log), "--report", str(report)],
                check=False,
                capture_output=True,
                text=True,
            )
            return result.returncode, json.loads(report.read_text())

    def test_advisory_warning_is_degraded_not_failed(self) -> None:
        rc, report = self.run_checker(self.make_log())
        self.assertEqual(rc, 0)
        self.assertTrue(report["ok"])
        self.assertEqual(report["health"], "degraded")
        self.assertEqual(report["last_good_stage"], "complete")
        self.assertEqual(report["evidence"]["cpu_count"], "1")

    def test_missing_required_stage_fails(self) -> None:
        text = self.make_log().replace("FLOW_DIAG 120 PIPE_IPC OK t_ms=1200\n", "")
        rc, report = self.run_checker(text)
        self.assertNotEqual(rc, 0)
        self.assertFalse(report["ok"])
        self.assertTrue(any("pipe" in item for item in report["failures"]))

    def test_fatal_kernel_signature_fails(self) -> None:
        rc, report = self.run_checker(self.make_log() + "Kernel panic - not syncing: test\n")
        self.assertNotEqual(rc, 0)
        self.assertTrue(any("Kernel panic" in item for item in report["failures"]))


if __name__ == "__main__":
    unittest.main()
