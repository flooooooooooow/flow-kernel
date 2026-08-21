# Linux system-health diagnostics

`flow-kernel` treats boot as an ordered, testable state machine rather than a single QEMU smoke test.

## Sequence

The machine-readable contract is `boot-sequence.json`. The current mandatory path is:

```text
artifact integrity
→ kernel entry
→ initramfs unpack
→ diagnostic PID 1
→ procfs
→ sysfs
→ core devices
→ writable userspace
→ CPU
→ memory
→ monotonic clock/timer
→ RNG
→ process creation/wait
→ signal delivery
→ pipe IPC
→ filesystem semantics
→ block-device discovery (advisory)
→ loopback/network stack
→ DNS resolver configuration (advisory)
→ namespaces
→ cgroups (advisory)
→ BPF capability evidence
→ libc-free Flow execution
→ complete
```

Required stages fail the job. Advisory stages may produce `WARN`; the system report becomes `degraded` but the boot remains valid.

## Guest protocol

`init.sh` runs as initramfs PID 1 and emits stable serial records:

```text
FLOW_DIAG 080 CLOCK_TIMER OK t_ms=1432
FLOW_EVIDENCE cpu_count=1
FLOW_EVIDENCE mem_total_kb=209072
FLOW_DIAG SUMMARY HEALTHY t_ms=1720
```

The sequence numbers are part of the test protocol. New checks should be inserted deliberately rather than relying on incidental kernel log ordering.

## Host verification

`check_boot.py` verifies:

- required stages exist;
- stages occur in contract order;
- diagnostic timestamps are monotonic;
- fatal kernel signatures such as panic, oops, BUG, rootfs failure, init death or diagnostic failure are absent;
- advisory warnings are retained as degradation rather than hidden;
- guest evidence is copied into `boot-health.json`;
- the last known-good stage is always recorded.

Run locally with:

```bash
python3 diagnostics/check_boot.py serial.log --report boot-health.json
```

## Regression comparison

`compare_health.py` compares a current report with a known-good report. It detects stages that disappeared, previously healthy stages that regressed, and large stage-timing regressions. Timing checks include an absolute slack so tiny early-boot measurements do not create noisy percentage regressions.

```bash
python3 diagnostics/compare_health.py current.json baseline.json --report regression.json
```

A known-good CI artifact can be promoted to the repository baseline after it is reviewed. The comparison code is independent of how the baseline is stored.

## Lifecycle

`reboot_init.sh` is a separate PID-1 lifecycle probe. QEMU runs it with `-no-reboot`; a successful forced reboot therefore terminates the VM rather than silently starting another boot. This keeps reboot-path validation independent from the main health sequence.

## Design rule

A diagnostic should test one invariant and emit one stable result. External Internet reachability is not a boot prerequisite: DNS configuration and similar environment-dependent checks are advisory unless a later test profile explicitly requires networking.
