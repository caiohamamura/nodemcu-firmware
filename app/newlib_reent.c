/*
 * newlib_reent.c - reentrant allocator shim for the ESP8266 build.
 *
 * The xtensa-lx106 newlib is built in reentrant mode: its public allocators
 * are thin wrappers over the _r variants (malloc(n) == _malloc_r(_REENT, n)),
 * and any newlib library code linked into the firmware - float-capable
 * vsnprintf/sprintf (app/libc c99-snprintf), strtod, mbedtls bignum, etc. -
 * calls _malloc_r / _free_r / _realloc_r directly.
 *
 * The firmware does NOT use newlib's heap. The Espressif SDK (libmain.a)
 * provides plain malloc/free/realloc routed to the single RTOS heap
 * (pvPortMalloc). Nothing otherwise provides the reentrant _r symbols, so the
 * link either fails with unresolved references or pulls in newlib's own
 * _sbrk-based heap - giving two heaps on ~80 KB of RAM and corrupting memory.
 *
 * These wrappers drop the unused struct _reent * and forward to the SDK's
 * plain allocators, forcing every allocation path through the one SDK heap.
 * No recursion: malloc/free/realloc here resolve to the SDK definitions, not
 * to newlib's. This matters most for TLS (mbedtls) builds.
 */
#include <stddef.h>

struct _reent;

extern void *malloc(size_t size);
extern void free(void *ptr);
extern void *realloc(void *ptr, size_t size);

void *_malloc_r(struct _reent *reent, size_t size)
{
  (void)reent;
  return malloc(size);
}

void _free_r(struct _reent *reent, void *ptr)
{
  (void)reent;
  free(ptr);
}

void *_realloc_r(struct _reent *reent, void *ptr, size_t size)
{
  (void)reent;
  return realloc(ptr, size);
}
