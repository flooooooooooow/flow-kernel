#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

if [[ -z "${PREFIX:-}" || "$PREFIX" != *com.termux* ]]; then
    echo "This setup script must run inside Termux." >&2
    exit 1
fi

arch="$(dpkg --print-architecture)"
case "$arch" in
    aarch64|amd64)
        ;;
    *)
        echo "flow-kernel Android VM support requires 64-bit Termux; got architecture: $arch" >&2
        exit 1
        ;;
esac

pkg update -y
pkg install -y x11-repo
pkg install -y curl coreutils qemu-system-x86-64

for command_name in curl md5sum qemu-system-x86_64; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Termux setup completed but required command is missing: $command_name" >&2
        exit 1
    fi
done

echo "Termux QEMU environment is ready."
echo "Run: bash android/run.sh"
