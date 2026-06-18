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
