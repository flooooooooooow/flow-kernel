#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TC_MAJOR="${TC_MAJOR:-17.x}"
TC_VERSION="${TC_VERSION:-17.1}"
TC_KERNEL="${TC_KERNEL:-6.18.35-tinycore64}"
TC_CONNECT_TIMEOUT="${TC_CONNECT_TIMEOUT:-10}"
TC_FETCH_TIMEOUT="${TC_FETCH_TIMEOUT:-90}"
OUT="${1:-$ROOT/build/tinycore}"

BASE_URLS=(
    "https://www.tinycorelinux.net/${TC_MAJOR}/x86_64/release/distribution_files"
    "https://ftp.icm.edu.pl/packages/linux-tinycorelinux/${TC_MAJOR}/x86_64/release/distribution_files"
    "https://ftp.dk.xemacs.org/mirrors/mirrors/pub/tinycorelinux/${TC_MAJOR}/x86_64/release/distribution_files"
)

mkdir -p "$OUT"

fetch()
{
    local name="$1"
    local dst="$OUT/$name"
    local base_url
    local url

    if [[ -s "$dst" ]]; then
        printf 'Using cached %s\n' "$dst"
        return
    fi

    for base_url in "${BASE_URLS[@]}"; do
        url="$base_url/$name"
        printf 'Fetching %s\n' "$url"
        if curl \
            --fail \
            --location \
            --retry 1 \
            --retry-all-errors \
            --connect-timeout "$TC_CONNECT_TIMEOUT" \
            --max-time "$TC_FETCH_TIMEOUT" \
            --output "$dst.part" \
            "$url"; then
            mv "$dst.part" "$dst"
            printf '%s\n' "$base_url" > "$OUT/source-url.txt"
            return
        fi
        rm -f "$dst.part"
        printf 'Tiny Core source failed, trying next mirror: %s\n' "$url" >&2
    done

    printf 'Tiny Core artifact unavailable from all configured mirrors: %s\n' "$name" >&2
    exit 1
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
    printf 'source=%s\n' "$(cat "$OUT/source-url.txt")"
    printf 'connect_timeout_seconds=%s\n' "$TC_CONNECT_TIMEOUT"
    printf 'fetch_timeout_seconds=%s\n' "$TC_FETCH_TIMEOUT"
    printf 'vmlinuz64_md5=%s\n' "$(awk '{print $1}' "$OUT/vmlinuz64.md5.txt")"
    printf 'corepure64_md5=%s\n' "$(awk '{print $1}' "$OUT/corepure64.gz.md5.txt")"
} > "$OUT/manifest.txt"

cat "$OUT/manifest.txt"
printf 'Tiny Core CorePure64 %s base ready in %s\n' "$TC_VERSION" "$OUT"
printf 'Kernel: %s\n' "$OUT/vmlinuz64"
printf 'Initramfs: %s\n' "$OUT/corepure64.gz"
