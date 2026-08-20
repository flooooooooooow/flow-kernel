#include <stdint.h>

static inline void flow_kernel_outb(uint16_t port, uint8_t value)
{
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

void flow_kernel_serial_init(void)
{
    flow_kernel_outb(0x3f8 + 1, 0x00);
    flow_kernel_outb(0x3f8 + 3, 0x80);
    flow_kernel_outb(0x3f8 + 0, 0x03);
    flow_kernel_outb(0x3f8 + 1, 0x00);
    flow_kernel_outb(0x3f8 + 3, 0x03);
    flow_kernel_outb(0x3f8 + 2, 0xc7);
    flow_kernel_outb(0x3f8 + 4, 0x0b);
}

void flow_kernel_serial_write(const char *text)
{
    while (*text != '\0') {
        flow_kernel_outb(0x3f8, (uint8_t)*text++);
    }
}

__attribute__((noreturn)) void flow_kernel_halt(void)
{
    for (;;) {
        __asm__ volatile ("cli; hlt");
    }
}
