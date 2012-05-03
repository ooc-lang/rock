
#if defined(va_copy)
#define va_copy_shim va_copy
#elif defined(__va_copy)
#define va_copy_shim __va_copy
#elif defined(__linux)
#define va_copy_shim(a, b) ((*a) = (*b))
#else
#error "Unsupported platform for va_copy!"
#endif

