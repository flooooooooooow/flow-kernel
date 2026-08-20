#!/usr/bin/env bash
set -euo pipefail

case "$(uname -m)" in
    aarch64|arm64|x86_64)
        ;;
    *)
        echo "flow-kernel: a 64-bit Termux environment is required for the x86_64 QEMU target" >&2
        exit 1
        ;;
esac

pkg update
pkg install -y x11-repo
pkg install -y qemu-system-x86-64

qemu-system-x86_64 --version
