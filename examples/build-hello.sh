#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOW="${FLOW:-$ROOT/../flow/flow}"
OUT="${1:-$ROOT/build/hello}"

if [[ ! -x "$FLOW" ]]; then
    echo "Flow compiler not found at $FLOW" >&2
    exit 1
fi

mkdir -p "$OUT"

"$FLOW" transpile "$ROOT/examples/hello.flow" \
    --c \
    --export hello_main \
    -o "$OUT/hello.c"

clang \
    -target x86_64-linux-gnu \
    -std=c11 \
    -ffreestanding \
    -fno-builtin \
    -fno-stack-protector \
    -fno-pic \
    -fno-pie \
    -O2 \
    -c "$OUT/hello.c" \
    -o "$OUT/hello-flow.o"

clang \
    -target x86_64-linux-gnu \
    -ffreestanding \
    -fno-pic \
    -fno-pie \
    -c "$ROOT/examples/start.S" \
    -o "$OUT/start.o"

ld.lld \
    -static \
    -nostdlib \
    -e _start \
    "$OUT/start.o" \
    "$OUT/hello-flow.o" \
    -o "$OUT/flow-hello"

if command -v readelf >/dev/null 2>&1; then
    readelf -l "$OUT/flow-hello" | grep -qv 'Requesting program interpreter'
fi

printf '%s\n' "$OUT/flow-hello"
