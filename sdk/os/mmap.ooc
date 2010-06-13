
// Linux / Apple version
version (linux || apple) {
    include sys/mman

    /* Constants */
    PROT_EXEC: extern Int
    PROT_WRITE: extern Int
    PROT_READ: extern Int
    PROT_NONE: extern Int

    MAP_FIXED: extern Int
    MAP_SHARED: extern Int
    MAP_PRIVATE: extern Int
    MAP_DENYWRITE: extern Int
    MAP_EXECUTABLE: extern Int
    MAP_NORESERVE: extern Int
    MAP_LOCKED: extern Int
    MAP_GROWSDOWN: extern Int
    MAP_ANONYMOUS: extern Int
    MAP_ANON: extern Int
    MAP_FILE: extern Int
    MAP_32BIT: extern Int
    MAP_POPULATE: extern Int
    MAP_NONBLOCK: extern Int

    MAP_FAILED: extern Pointer

    MADV_NORMAL: extern Int
    MADV_SEQUENTIAL: extern Int
    MADV_RANDOM: extern Int
    MADV_WILLNEED: extern Int
    MADV_DONTNEED: extern Int

    MS_ASYNC: extern Int
    MS_SYNC: extern Int
    MS_INVALIDATE: extern Int

    /* Functions */
    /*start: Pointer, length: SizeT, prot: Int, flags: Int, fd: Int, offset: Int */
    mmap: extern func(Pointer, SizeT, Int, Int, Int, Int) -> Pointer
    /* start: Pointer, length: SizeT */
    munmap: extern func(Pointer, SizeT) -> Int
    /* addr: Pointer, length: SizeT, prot: Int */
    mprotect: extern func(Pointer, SizeT, Int) -> Int
    /* addr: Pointer, length: SizeT, advice: Int */
    madvise: extern func(Pointer, SizeT, Int) -> Int
    /* addr: Pointer, length: SizeT, vec: Char* */
    mincore: extern func(Pointer, SizeT, Char*) -> Int
    /* addr: Pointer, length: SizeT, inherit: Int */
    minherit: extern func(Pointer, SizeT, Int) -> Int
    /* addr: Pointer, length: SizeT, flags: Int */
    msync: extern func(Pointer, SizeT, Int) -> Int
    /* addr: Pointer, length: SizeT */
    mlock: extern func(Pointer, SizeT) -> Int
    /* addr: Pointer, length: SizeT */
    munlock: extern func(Pointer, SizeT) -> Int

}

// Windows equivalent
version (windows) {

    include windows

    VirtualProtect: extern func (Pointer, SizeT, Long /* DWORD */, Long* /* PDWORD */) -> Bool

    PAGE_EXECUTE,
    PAGE_EXECUTE_READ,
    PAGE_EXECUTE_READWRITE,
    PAGE_EXECUTE_WRITECOPY,
    PAGE_NOACCESS,
    PAGE_READONLY,
    PAGE_READWRITE,
    PAGE_WRITECOPY : extern Long

}



