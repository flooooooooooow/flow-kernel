# Flow Kernel

A freestanding kernel written in Flow.

The first target is x86_64 booted through Multiboot2. Flow owns the kernel entry contract and policy-facing primitives; the architecture layer is restricted to CPU operations that cannot yet be expressed portably in Flow.

The current base boots in 32-bit Multiboot2 mode, establishes an identity-mapped 1 GiB long-mode address space with 2 MiB pages, enters x86_64 long mode, installs a 64 KiB kernel stack, and calls the stable Flow C ABI entry `flow_export_kernel_main`. The Flow entry validates the Multiboot2 contract and reports boot state over COM1 serial.

## Build

The kernel consumes the Flow compiler as an external dependency. Set `FLOW` to the Flow driver you want to use, or place a sibling checkout at `../flow`.

```bash
git clone https://github.com/flooooooooooow/flow.git ../flow
FLOW=../flow/flow bash x86_64/build.sh
```

The build requires Flow's normal transpiler dependencies plus `clang` and `ld.lld`. If `grub-file` is installed, the resulting ELF is also validated as Multiboot2.

## Boot

```bash
FLOW=../flow/flow bash x86_64/run.sh
```

That additionally requires `grub-mkrescue` and `qemu-system-x86_64`. Successful boot reaches the serial message `Flow kernel: boot contract accepted`.

## Boot on Android

The same x86_64 ISO can boot on a 64-bit Android phone through Termux and QEMU TCG without root or bootloader changes.

```bash
pkg update
pkg install x11-repo
pkg install qemu-system-x86-64
bash android/termux-run.sh /path/to/flow-kernel.iso
```

CI publishes a `flow-kernel-android-x86_64` artifact containing the ISO, Android runner, and checksum manifest. See [`android/README.md`](android/README.md) for the complete phone workflow.

## Roadmap

The next layers are Multiboot2 memory-map ingestion, a physical page allocator, interrupt/exception tables, timer-driven scheduling, syscall entry, virtual memory ownership, and then the eBPF verifier/interpreter/JIT hooks. eBPF should consume explicit kernel hook surfaces rather than becoming part of the boot substrate.

An `aarch64` architecture target is also planned so ARM64 Android devices can boot Flow under QEMU's `virt` machine without translating an x86_64 guest.
