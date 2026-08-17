#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${1:-$ROOT/build/tinycore}"

if [[ ! -s "$BUILD/vmlinuz64" || ! -s "$BUILD/corepure64.gz" ]]; then
    bash "$ROOT/tinycore/fetch.sh" "$BUILD"
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo 'qemu-system-x86_64 is required' >&2
    exit 1
fi

exec qemu-system-x86_64 \
    -machine accel=tcg \
    -cpu max \
    -m "${FLOW_KERNEL_RAM:-256M}" \
    -kernel "$BUILD/vmlinuz64" \
    -initrd "$BUILD/corepure64.gz" \
    -append "console=ttyS0 quiet ${FLOW_KERNEL_CMDLINE:-}" \
    -nographic \
    -no-reboot
