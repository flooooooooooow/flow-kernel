# Libc-free syscall examples

The canonical x86_64 bindings live in `linux/x86_64/abi.flow`. They return raw Linux syscall results; negative values are `-errno`.

## File descriptors and `write`

```flow
let stdout: i32 = 1
let result: i64 = flow_linux_write(stdout, data, count)
if result < 0 {
    # handle -errno
}
```

File descriptors are `i32`; byte counts and sizes are `u64`.

## `exit`

```flow
flow_linux_exit(0)
```

`exit` never returns. Minimal binaries normally use the `_start` stub in `examples/start.S`, which exits with the Flow entrypoint's return value.

## `mmap`

```flow
# PROT_READ | PROT_WRITE = 3
# MAP_PRIVATE | MAP_ANONYMOUS = 34
let raw: i64 = flow_linux_mmap(null, 4096, 3, 34, -1, 0)
if raw < 0 {
    # allocation failed: raw is -errno
}
```

The initial binding intentionally returns the raw machine-word result as `i64`; a higher-level typed pointer wrapper can be layered on top without changing the Linux ABI shim.

## `clock_gettime`

```flow
# CLOCK_MONOTONIC = 1
let result: i64 = flow_linux_clock_gettime(1, timespec_ptr)
if result < 0 {
    # clock read failed
}
```

The caller owns the two-`i64` `timespec` storage for the x86_64 ABI. Keeping the primitive pointer-based avoids forcing a kernel C struct representation into the Flow language.

## Minimal service

`examples/hello.flow` demonstrates the deployed shape used by CI: Flow logic plus a tiny direct-syscall shim, transpiled to C and linked with `-static -nostdlib`. CI checks that the resulting ELF has neither a program interpreter nor unresolved symbols before inserting it into the CorePure64 initramfs.
