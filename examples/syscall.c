typedef unsigned long flow_u64;
typedef long flow_i64;

flow_i64 flow_hello_write(char *data, flow_u64 count)
{
    flow_i64 result;
    __asm__ volatile (
        "syscall"
        : "=a"(result)
        : "a"(1), "D"(1), "S"(data), "d"(count)
        : "rcx", "r11", "memory"
    );
    return result;
}
