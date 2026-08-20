#!/usr/bin/env bash
set -euo pipefail

ISO="${1:-${FLOW_KERNEL_ISO:-$PWD/flow-kernel.iso}}"
QEMU="${FLOW_KERNEL_QEMU:-qemu-system-x86_64}"
MEMORY="${FLOW_KERNEL_MEMORY:-128M}"

if ! command -v "$QEMU" >/dev/null 2>&1; then
    echo "flow-kernel: $QEMU is not installed" >&2
    echo "flow-kernel: on Termux run: pkg install x11-repo && pkg install qemu-system-x86-64" >&2
    exit 1
fi

if [[ ! -r "$ISO" ]]; then
    echo "flow-kernel: ISO not found or unreadable: $ISO" >&2
    echo "usage: $0 /path/to/flow-kernel.iso" >&2
    exit 1
fi

exec "$QEMU" \
    -machine accel=tcg \
    -m "$MEMORY" \
    -cdrom "$ISO" \
    -boot d \
    -serial stdio \
    -display none \
    -monitor none \
    -no-reboot \
    -no-shutdown
