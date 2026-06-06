#include <stdlib.h>
#include <string.h>

void *mbedtls_calloc_wrap(size_t n, size_t sz) {
    void *ptr = calloc(n, sz);
    if (ptr) {
        memset(ptr, 0, n * sz);
    }
    return ptr;
}

void mbedtls_free_wrap(void *p) { free(p); }
