#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${1:-$ROOT/build/tinycore}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "qemu-system-x86_64 is required. Run: bash android/setup-termux.sh" >&2
    exit 1
fi

export FLOW_KERNEL_RAM="${FLOW_KERNEL_RAM:-256M}"
exec bash "$ROOT/tinycore/run.sh" "$BUILD"
