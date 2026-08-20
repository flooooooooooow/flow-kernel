# Flow Kernel on Android

This boots the current x86_64 Multiboot2 Flow kernel inside QEMU TCG on a 64-bit Android device. It does not replace Android, unlock the bootloader, require root, or modify the phone kernel.

## 1. Install QEMU in Termux

Use a current Termux installation, then run:

```bash
bash termux-setup.sh
```

The setup helper enables the Termux X11 package repository and installs `qemu-system-x86-64`, which provides the `qemu-system-x86_64` binary used by the runner.

Equivalent manual commands are:

```bash
pkg update
pkg install x11-repo
pkg install qemu-system-x86-64
```

No X11 application is needed because Flow kernel output is carried over the emulated serial port.

## 2. Get the kernel image

Download the `flow-kernel-android-x86_64` artifact from a successful GitHub Actions run and extract it into a directory visible to Termux. The artifact contains:

```text
flow-kernel.iso
termux-run.sh
termux-setup.sh
README.md
SHA256SUMS
```

Verify the image before booting:

```bash
sha256sum -c SHA256SUMS
```

## 3. Boot Flow

From the extracted artifact directory:

```bash
bash termux-run.sh flow-kernel.iso
```

A successful boot reaches:

```text
Flow kernel: entry
Flow kernel: boot contract accepted
```

QEMU is intentionally configured with TCG rather than KVM because the current guest is x86_64 while normal modern Android phones are ARM64.

Press `Ctrl+A`, then `X` to terminate QEMU if required.

## Environment overrides

The runner accepts these optional variables:

```bash
FLOW_KERNEL_ISO=/path/to/flow-kernel.iso
FLOW_KERNEL_QEMU=qemu-system-x86_64
FLOW_KERNEL_MEMORY=128M
```

For example:

```bash
FLOW_KERNEL_MEMORY=256M bash termux-run.sh flow-kernel.iso
```

## Next architecture target

This Android path deliberately validates the existing kernel unchanged. The next native-emulation target should be `aarch64` using QEMU's `virt` machine so ARM64 Android hosts no longer pay the x86_64 instruction-translation cost.
