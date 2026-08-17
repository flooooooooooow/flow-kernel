.section .text
.global _start
.type _start,@function
_start:
    xor %rbp, %rbp
    and $-16, %rsp
    call flow_export_hello_main
    mov %eax, %edi
    mov $60, %eax
    syscall
    ud2
