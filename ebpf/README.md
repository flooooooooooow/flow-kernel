# Flow eBPF

Linux eBPF is the first kernel-facing execution target for Flow on the Tiny Core base.

The implementation should lower a verifier-safe Flow subset to eBPF rather than recreate Linux kernel infrastructure. Initial scope:

- BPF ELF emission and section metadata
- maps and map declarations
- verifier-safe scalar and pointer operations
- Linux helper bindings
- tracepoints and kprobes
- XDP programs
- TC ingress/egress hooks
- BTF type ingestion
- CO-RE-style relocations
- deterministic host-side tests against the Linux verifier

The Tiny Core image is intentionally only the execution substrate. Compiler/backend work belongs in `flooooooooooow/flow`; this repository owns Linux integration, fixtures, boot images and end-to-end kernel tests.
