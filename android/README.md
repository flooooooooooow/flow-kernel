# Android / Termux

Flow's Android VM path boots the same pinned Tiny Core CorePure64 guest used by normal `flow-kernel` QEMU runs. Android is only the QEMU host; there is no bootloader replacement, Android kernel modification, root requirement, or separate Flow kernel architecture.

This path requires a 64-bit Termux installation. The current canonical guest is x86_64 CorePure64 and therefore runs through QEMU TCG on ARM64 Android. A native ARM64 guest should only be added when the canonical Tiny Core substrate and Flow target support it rather than creating a phone-only fork.

From the repository root in Termux:

```sh
bash android/setup-termux.sh
bash android/run.sh
```

`android/setup-termux.sh` enables the Termux X11 repository and installs the maintained `qemu-system-x86-64` package plus the tools used by `tinycore/fetch.sh`. `android/run.sh` then delegates directly to `tinycore/run.sh`, so image pinning, checksum verification, serial console behaviour, RAM configuration, and kernel command-line overrides stay identical to the normal Flow kernel path.

The Tiny Core artifacts are cached under `build/tinycore` by default. Pass another build directory as the first argument to `android/run.sh` if needed.

Useful overrides are the same as the canonical runner:

```sh
FLOW_KERNEL_RAM=512M bash android/run.sh
FLOW_KERNEL_CMDLINE="debug" bash android/run.sh
```
