#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="${1:-$HERE/build}"
FLOW="${FLOW:-$HERE/../../flow/flow}"

if [[ ! -x "$FLOW" ]]; then
    echo "Flow compiler not found or not executable: $FLOW" >&2
    echo "Set FLOW=/path/to/flow/flow or place a sibling checkout at ../flow." >&2
    exit 1
fi

mkdir -p "$BUILD"

"$FLOW" transpile "$HERE/kernel.flow" \
    --c \
    --export kernel_main kernel_abi_version kernel_page_size kernel_boot_magic_valid kernel_page_count \
    -o "$BUILD/kernel.c"

clang \
    -target x86_64-unknown-none-elf \
    -std=c11 \
    -ffreestanding \
    -fno-builtin \
    -fno-stack-protector \
    -fno-pic \
    -fno-pie \
    -mno-red-zone \
    -ffunction-sections \
    -fdata-sections \
    -O2 \
    -c "$BUILD/kernel.c" \
    -o "$BUILD/kernel-flow.o"

clang \
    -target x86_64-unknown-none-elf \
    -ffreestanding \
    -fno-pic \
    -fno-pie \
    -mno-red-zone \
    -c "$HERE/boot.S" \
    -o "$BUILD/boot.o"

ld.lld \
    -nostdlib \
    --gc-sections \
    -T "$HERE/linker.ld" \
    "$BUILD/boot.o" \
    "$BUILD/kernel-flow.o" \
    -o "$BUILD/flow-kernel.elf"

if command -v grub-file >/dev/null 2>&1; then
    grub-file --is-x86-multiboot2 "$BUILD/flow-kernel.elf"
fi

printf '%s\n' "$BUILD/flow-kernel.elf"
