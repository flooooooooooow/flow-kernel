#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="${1:-$HERE/build}"
ISO_ROOT="$BUILD/iso"
ISO="$BUILD/flow-kernel.iso"

command -v grub-mkrescue >/dev/null 2>&1 || { echo "grub-mkrescue is required" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null 2>&1 || { echo "qemu-system-x86_64 is required" >&2; exit 1; }

bash "$HERE/build.sh" "$BUILD"

rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot/grub"
cp "$BUILD/flow-kernel.elf" "$ISO_ROOT/boot/flow-kernel.elf"
cp "$HERE/grub.cfg" "$ISO_ROOT/boot/grub/grub.cfg"
grub-mkrescue -o "$ISO" "$ISO_ROOT"

exec qemu-system-x86_64 \
    -machine accel=tcg \
    -m 128M \
    -cdrom "$ISO" \
    -serial stdio \
    -display none \
    -no-reboot \
    -no-shutdown
