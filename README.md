# Flow Kernel

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

## Fetch the Tiny Core base

The default tracks the CorePure64 `17.x` release line. Override `TC_MAJOR` when intentionally moving to another Tiny Core line.

```bash
bash tinycore/fetch.sh
```

Artifacts are placed under `build/tinycore/`.

## Boot it

```bash
bash tinycore/run.sh
```

This boots the Tiny Core Linux kernel and initramfs directly in QEMU with the serial console attached to the terminal. No GRUB image and no Flow-owned architecture bootstrap are involved.

## Flow compiler

Flow remains a separate dependency. Kernel-facing Flow programs in this repository should compile against Linux ABIs or to eBPF; the language/compiler belongs in `flooooooooooow/flow` and is checked out independently in CI.

## Roadmap

The next work is deliberately Linux-native: add a Flow-to-eBPF target, BTF-aware bindings, maps, verifier-safe helpers, tracepoint/kprobe hooks, XDP, TC hooks and eventually CO-RE-style relocatable programs. User-space Flow services can remain tiny and run directly on CorePure64.
