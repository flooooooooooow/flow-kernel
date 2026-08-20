#ifndef FLOW_KERNEL_FREESTANDING_STDLIB_H
#define FLOW_KERNEL_FREESTANDING_STDLIB_H

#include <stddef.h>

void *malloc(size_t size);
void free(void *ptr);
int atexit(void (*function)(void));
__attribute__((noreturn)) void abort(void);

#endif
