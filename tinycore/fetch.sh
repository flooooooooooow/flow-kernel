#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TC_MAJOR="${TC_MAJOR:-17.x}"
TC_VERSION="${TC_VERSION:-17.0}"
OUT="${1:-$ROOT/build/tinycore}"
BASE_URL="https://www.tinycorelinux.net/${TC_MAJOR}/x86_64/release/distribution_files"

mkdir -p "$OUT"

fetch()
{
    local name="$1"
    local url="$BASE_URL/$name"
    local dst="$OUT/$name"

    if [[ -s "$dst" ]]; then
        printf 'Using cached %s\n' "$dst"
        return
    fi

    printf 'Fetching %s\n' "$url"
    curl --fail --location --retry 3 --output "$dst.part" "$url"
    mv "$dst.part" "$dst"
}

fetch vmlinuz64
fetch corepure64.gz

printf 'Tiny Core CorePure64 %s base ready in %s\n' "$TC_VERSION" "$OUT"
printf 'Kernel: %s\n' "$OUT/vmlinuz64"
printf 'Initramfs: %s\n' "$OUT/corepure64.gz"
