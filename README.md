# Flow Kernel

[![Kernel CI](https://github.com/flooooooooooow/flow-kernel/actions/workflows/ci.yml/badge.svg)](https://github.com/flooooooooooow/flow-kernel/actions/workflows/ci.yml)
[![Diagnostics](https://github.com/flooooooooooow/flow-kernel/actions/workflows/diagnostics.yml/badge.svg)](https://github.com/flooooooooooow/flow-kernel/actions/workflows/diagnostics.yml)
[![GitHub Pages](https://github.com/flooooooooooow/flow-kernel/actions/workflows/pages.yml/badge.svg)](https://github.com/flooooooooooow/flow-kernel/actions/workflows/pages.yml)

Flow systems integration on top of a deliberately tiny Linux base.

`flow-kernel` no longer implements its own bootloader, page tables, scheduler, interrupt subsystem, or virtual-memory manager. Those are Linux responsibilities. The base target is Tiny Core Linux CorePure64: a minimal command-line Linux system that gives Flow a mature x86_64 kernel, drivers, networking, processes, namespaces, cgroups, perf and the native Linux eBPF surface without dragging in a conventional desktop distribution.

## Architecture

```text
Linux kernel
  ↑
Tiny Core CorePure64 userspace
  ↑
Flow system services / kernel-facing components
  ↑
Flow eBPF, XDP, tracing and driver experiments
```

Tiny Core is the substrate, not a fork. We consume its `vmlinuz64` and `corepure64.gz` release artifacts directly.

## Repository boundary

`flooooooooooow/flow` owns language syntax, parser/type-system behaviour, generic compiler infrastructure and reusable target/backend machinery. `flow-kernel` owns Linux-specific ABI bindings, kernel-facing Flow libraries, eBPF program APIs and examples, loaders/control-plane code, Tiny Core packaging, kernel integration tests and systems benchmarks. Changes needed in the Flow compiler should be implemented upstream rather than copied into this repository.

## Fetch the Tiny Core base

The default tracks Tiny Core CorePure64 17.1 with Linux `6.18.35-tinycore64`. The fetch script tries configured public mirrors, verifies Tiny Core's published MD5 sidecars, and records a manifest containing the exact version, source mirror and checksums used.

```bash
bash tinycore/fetch.sh
```

Artifacts are placed under `build/tinycore/`.

## Boot it

```bash
bash tinycore/run.sh
```

This boots the Tiny Core Linux kernel and initramfs directly in QEMU with the serial console attached to the terminal. No GRUB image and no Flow-owned architecture bootstrap are involved.

## Deterministic system-health sequence

A successful boot is not treated as a single boolean. CI runs an ordered diagnostic PID 1 and validates the system as a state machine:

```text
kernel → initramfs → PID 1 → procfs → sysfs → devices → writable state
→ CPU → memory → timer → RNG → processes → signals → pipes → filesystem
→ block devices → network → DNS → namespaces → cgroups → BPF → Flow → complete
```

Every guest stage emits a stable serial marker and monotonic timestamp. The host verifier rejects missing/out-of-order required stages, kernel panic/oops/BUG/rootfs/init-failure signatures, and non-monotonic timing. Environment-dependent checks such as DNS, block-device presence and cgroups can report advisory degradation without being confused with boot failure.

The generated `boot-health.json` records the overall health state, last known-good stage, per-stage timings, failures/degradation, and evidence such as kernel release, CPU count, RAM, entropy, block devices and network interfaces. A separate QEMU lifecycle probe verifies the guest reboot path. See [`diagnostics/README.md`](diagnostics/README.md).

## Verification

CI caches the Tiny Core base, revalidates the published checksum sidecars, records the exact source/version/checksums, captures serial boot logs, exercises the full system-health sequence, verifies a libc-free Flow executable inside the guest, validates reboot behaviour, and archives the resulting health/evidence reports. The eBPF/BTF feature set is checked from the real Tiny Core kernel config when that metadata is available instead of inferred from the Linux version.

## Flow compiler

Flow remains a separate dependency. Kernel-facing Flow programs in this repository should compile against Linux ABIs or to eBPF; the language/compiler belongs in `flooooooooooow/flow` and is checked out independently in CI.

## Roadmap

The next work is deliberately Linux-native: finish the Flow-to-eBPF verifier path, BTF-aware bindings, maps, verifier-safe helpers, tracepoint/kprobe hooks, XDP, TC hooks and eventually CO-RE-style relocatable programs. User-space Flow services can remain tiny and run directly on CorePure64.
