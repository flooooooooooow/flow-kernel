#ifndef FLOW_KERNEL_FREESTANDING_STDIO_H
#define FLOW_KERNEL_FREESTANDING_STDIO_H

#include <stddef.h>

typedef struct flow_kernel_FILE FILE;

extern FILE *stderr;

int printf(const char *format, ...);
int fprintf(FILE *stream, const char *format, ...);
int snprintf(char *buffer, size_t size, const char *format, ...);

#endif
