# Flow eBPF

This directory is the kernel-facing eBPF layer for Flow.

The compiler implementation itself belongs in `flooooooooooow/flow`. This repository owns the Linux program model around that backend: section conventions, helper/map bindings, verifier-safe APIs, loaders, attach/detach workflows, Tiny Core integration, examples and end-to-end kernel tests.

## Target contract

The intended compiler contract is a little-endian Linux eBPF target (`bpfel`) lowered through Flow's MLIR/LLVM path into standalone eBPF ELF objects.

The first backend must enforce these invariants before verifier load:

- no dependency on the normal Flow runtime
- no dynamic allocation
- no exceptions or unwinding
- bounded/verifier-safe loops
- bounded stack use
- verifier-safe pointer provenance
- no unsupported indirect calls or dynamic dispatch
- target-specific helper availability
- deterministic ELF section/program metadata

## Canonical lowering

```text
Flow source
  → Flow AST / typed IR
  → MLIR / LLVM lowering
  → LLVM BPF target (bpfel)
  → standalone eBPF ELF
  → Linux verifier
  → attach to Linux hook
```

## Initial hook order

1. tracepoints
2. kprobes/fentry where supported
3. ring-buffer event delivery
4. XDP
5. TC ingress/egress
6. CO-RE/BTF-based portable programs

Stock Tiny Core kernel capabilities are inspected explicitly in CI. If CorePure64 does not expose the BPF/BTF features required by a phase, the project should add a reproducible Tiny Core kernel variant rather than silently assuming support.
