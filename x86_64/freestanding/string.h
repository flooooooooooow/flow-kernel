#ifndef FLOW_KERNEL_FREESTANDING_STRING_H
#define FLOW_KERNEL_FREESTANDING_STRING_H

#include <stddef.h>

size_t strlen(const char *text);
int strcmp(const char *lhs, const char *rhs);
int strncmp(const char *lhs, const char *rhs, size_t count);
void *memcpy(void *dst, const void *src, size_t count);
void *memmove(void *dst, const void *src, size_t count);
void *memset(void *dst, int value, size_t count);

#endif
