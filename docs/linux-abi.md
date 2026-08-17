# Flow Linux ABI boundary

`flow-kernel` targets the Linux userspace ABI directly for tiny services and the Linux eBPF ABI for kernel-facing programs. It does not introduce a private kernel ABI.

## Supported userspace ABI

The initial target is Linux x86_64. Flow scalar mappings are intentionally exact-width:

| Linux ABI concept | Flow type |
|---|---|
| `char` / byte | `u8` |
| `short` | `i16` / `u16` |
| `int` | `i32` / `u32` |
| `long`, `ssize_t`, syscall return | `i64` |
| `unsigned long`, `size_t` | `u64` |
| address / opaque pointer | `ptr<void>` |
| C string input | `string` when Flow owns the storage, otherwise `ptr<u8>` |
| file descriptor | `i32` |

The syscall layer does not translate `errno`. Raw Linux syscall results are returned directly: non-negative values indicate success and negative values are `-errno`.

## Initial syscall surface

The first libc-free surface is deliberately small:

- `write(fd, buffer, count)`
- `exit(status)`
- `mmap(address, length, protection, flags, fd, offset)`
- `clock_gettime(clock_id, timespec_ptr)`

These cover basic output, process termination, memory acquisition, clocks and file-descriptor based service code without introducing libc as a runtime requirement.

## Stable FFI pattern

Architecture-specific syscall instructions live in tiny `@cEmbed` shims. Flow owns type checking and service logic; the shim owns only the ABI register convention and `syscall` instruction. No libc symbol should be required by a deployed CorePure64 service.

For x86_64 Linux, syscall arguments use `rax` for the syscall number and `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9` for arguments 1–6. The wrappers in `linux/x86_64/abi.flow` encode that boundary.

## Repository boundary

Belongs in `flow-kernel`:

- Linux ABI bindings and fixtures
- Tiny Core integration and packaging
- libc-free service examples
- eBPF loader/runtime integration
- end-to-end QEMU and kernel tests

Belongs in `flooooooooooow/flow`:

- language syntax
- compiler IR and lowering
- target selection such as `bpfel`
- verifier-aware compiler diagnostics
- object emission and backend implementation
