#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct flow_kernel_FILE {
    int reserved;
};

static FILE flow_kernel_stderr;
FILE *stderr = &flow_kernel_stderr;

int printf(const char *format, ...)
{
    (void)format;
    return 0;
}

int fprintf(FILE *stream, const char *format, ...)
{
    (void)stream;
    (void)format;
    return 0;
}

int snprintf(char *buffer, size_t size, const char *format, ...)
{
    (void)format;
    if (buffer != NULL && size != 0) {
        buffer[0] = '\0';
    }
    return 0;
}

void *malloc(size_t size)
{
    (void)size;
    return NULL;
}

void free(void *ptr)
{
    (void)ptr;
}

int atexit(void (*function)(void))
{
    (void)function;
    return 0;
}

__attribute__((noreturn)) void abort(void)
{
    for (;;) {
        __asm__ volatile ("cli; hlt");
    }
}

size_t strlen(const char *text)
{
    size_t length = 0;
    while (text[length] != '\0') {
        ++length;
    }
    return length;
}

int strcmp(const char *lhs, const char *rhs)
{
    while (*lhs != '\0' && *lhs == *rhs) {
        ++lhs;
        ++rhs;
    }
    return (int)(unsigned char)*lhs - (int)(unsigned char)*rhs;
}

int strncmp(const char *lhs, const char *rhs, size_t count)
{
    while (count != 0 && *lhs != '\0' && *lhs == *rhs) {
        ++lhs;
        ++rhs;
        --count;
    }
    if (count == 0) {
        return 0;
    }
    return (int)(unsigned char)*lhs - (int)(unsigned char)*rhs;
}

void *memcpy(void *dst, const void *src, size_t count)
{
    unsigned char *out = (unsigned char *)dst;
    const unsigned char *in = (const unsigned char *)src;
    for (size_t i = 0; i < count; ++i) {
        out[i] = in[i];
    }
    return dst;
}

void *memmove(void *dst, const void *src, size_t count)
{
    unsigned char *out = (unsigned char *)dst;
    const unsigned char *in = (const unsigned char *)src;
    if (out < in) {
        for (size_t i = 0; i < count; ++i) {
            out[i] = in[i];
        }
    } else if (out > in) {
        while (count != 0) {
            --count;
            out[count] = in[count];
        }
    }
    return dst;
}

void *memset(void *dst, int value, size_t count)
{
    unsigned char *out = (unsigned char *)dst;
    for (size_t i = 0; i < count; ++i) {
        out[i] = (unsigned char)value;
    }
    return dst;
}
