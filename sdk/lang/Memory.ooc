
// as goofy as it sounds, memory-related routines are actually in string.h
// yay C. (Also, Google Native Client doesn't have memory.h)
include string

version(!gc) {
    // GC_MALLOC zeroes the memory, so in the non-gc version, we prefer to use calloc
    // to the expense of some performance. If you want to use malloc instead - do so
    // at your own risks. Some sdk classes may not zero their every field.

    //gc_malloc: extern(malloc) func (size: SizeT) -> Pointer
    gc_malloc: func (size: SizeT) -> Pointer {
        gc_calloc(1, size)
    }
    gc_malloc_atomic: extern(malloc) func (size: SizeT) -> Pointer
    gc_strdup: extern(strdup) func (str: CString) -> CString
    gc_realloc: extern(realloc) func (ptr: Pointer, size: SizeT) -> Pointer
    gc_calloc: extern(calloc) func (nmemb: SizeT, size: SizeT) -> Pointer
    gc_free: extern(free) func (ptr: Pointer)
}

version(gc) {
    include gc/gc | (GC_THREADS)

    gc_malloc: extern(GC_malloc) func (size: SizeT) -> Pointer
    gc_malloc_atomic: extern(GC_malloc_atomic) func (size: SizeT) -> Pointer
    gc_strdup: extern(GC_strdup) func (str: CString) -> CString
    gc_realloc: extern(GC_realloc) func (ptr: Pointer, size: SizeT) -> Pointer
    gc_calloc: func (nmemb: SizeT, size: SizeT) -> Pointer {
        gc_malloc(nmemb * size)
    }
    gc_free: extern(GC_free) func (ptr: Pointer)
}

// memory management
memset: extern func (Pointer, Int, SizeT) -> Pointer
memcmp: extern func (Pointer, Pointer, SizeT) -> Int
memmove: extern func (Pointer, Pointer, SizeT)
memcpy: extern func (Pointer, Pointer, SizeT)
free: extern func (Pointer)

// note: sizeof is intentionally not here. sizeof(Int) will be translated
// to sizeof(Int_class()), and thus will always give the same value for
// all types. 'Int size' should be used instead, which will be translated
// to 'Int_class()->size'
