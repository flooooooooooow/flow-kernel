#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TC_MAJOR="${TC_MAJOR:-17.x}"
TC_VERSION="${TC_VERSION:-17.0}"
TC_KERNEL="${TC_KERNEL:-6.18.2-tinycore64}"
TC_CONNECT_TIMEOUT="${TC_CONNECT_TIMEOUT:-15}"
TC_FETCH_TIMEOUT="${TC_FETCH_TIMEOUT:-120}"
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
    if ! curl \
        --fail \
        --location \
        --retry 3 \
        --retry-all-errors \
        --connect-timeout "$TC_CONNECT_TIMEOUT" \
        --max-time "$TC_FETCH_TIMEOUT" \
        --output "$dst.part" \
        "$url"; then
        rm -f "$dst.part"
        printf 'Tiny Core artifact unavailable or timed out after %ss: %s\n' "$TC_FETCH_TIMEOUT" "$url" >&2
        exit 1
    fi
    mv "$dst.part" "$dst"
}

verify_md5()
{
    local name="$1"
    local sum_file="$OUT/$name.md5.txt"

    fetch "$name.md5.txt"
    (
        cd "$OUT"
        md5sum --check "$(basename "$sum_file")"
    )
}

fetch vmlinuz64
fetch corepure64.gz
verify_md5 vmlinuz64
verify_md5 corepure64.gz

gzip -t "$OUT/corepure64.gz"

{
    printf 'tinycore_major=%s\n' "$TC_MAJOR"
    printf 'tinycore_version=%s\n' "$TC_VERSION"
    printf 'kernel_version=%s\n' "$TC_KERNEL"
    printf 'source=%s\n' "$BASE_URL"
    printf 'connect_timeout_seconds=%s\n' "$TC_CONNECT_TIMEOUT"
    printf 'fetch_timeout_seconds=%s\n' "$TC_FETCH_TIMEOUT"
    printf 'vmlinuz64_md5=%s\n' "$(awk '{print $1}' "$OUT/vmlinuz64.md5.txt")"
    printf 'corepure64_md5=%s\n' "$(awk '{print $1}' "$OUT/corepure64.gz.md5.txt")"
} > "$OUT/manifest.txt"

cat "$OUT/manifest.txt"
printf 'Tiny Core CorePure64 %s base ready in %s\n' "$TC_VERSION" "$OUT"
printf 'Kernel: %s\n' "$OUT/vmlinuz64"
printf 'Initramfs: %s\n' "$OUT/corepure64.gz"
