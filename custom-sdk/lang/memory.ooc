include memory

version(gc) {
    include gc/gc
    
    gc_malloc: extern(GC_MALLOC) func (size: SizeT) -> Pointer
    gc_malloc_atomic: extern(GC_MALLOC_ATOMIC) func (size: SizeT) -> Pointer
    gc_realloc: extern(GC_REALLOC) func (ptr: Pointer, size: SizeT) -> Pointer
    gc_calloc: func (nmemb: SizeT, size: SizeT) -> Pointer {
        gc_malloc(nmemb * size)
    }
}

/*
version(!gc) {
    gc_malloc: extern(malloc) func (size: SizeT) -> Pointer
    /*gc_malloc: func (size: SizeT) -> Pointer {
        gc_calloc(1, size)
    }*/ /*
    gc_malloc_atomic: extern(malloc) func (size: SizeT) -> Pointer
    gc_realloc: extern(realloc) func (ptr: Pointer, size: SizeT) -> Pointer
    gc_calloc: extern(calloc) func (nmemb: SizeT, size: SizeT) -> Pointer
}*/

// memory management
sizeof: extern func (...) -> SizeT
memset: extern func (Pointer, Int, SizeT) -> Pointer
memcmp: extern func (Pointer, Pointer, SizeT) -> Int
memmove: extern func (Pointer, Pointer, SizeT)
memcpy: extern func (Pointer, Pointer, SizeT)
free: extern func (Pointer)
