include fcntl

FileDescriptor: cover from Int


close: extern func(FileDescriptor) -> Int
open: extern func(CString, Int) -> FileDescriptor
read: extern func(FileDescriptor, Pointer, Int) -> Int
write: extern func(FileDescriptor, Pointer, Int) -> Int

Command: enum {
    // Duplicate
    dupfd: extern(F_DUPD)

    // File descriptor flags
    getfd: extern(F_GETFD)
    setfd: extern(F_SETFD)

    // File status flags
    getfl: extern (F_GETFL)
    setfl: extern (F_SETFL)

    // Locks
    getlk: extern (F_GETLK)
    setlk: extern (F_SETLK)
    setlkw: extern (F_SETLKW)

    // Process / process group IDs
    getown: extern (F_GETOWN)
    setown: extern (F_SETOWN)
}

fcntl: extern func(FileDescriptor, Command, ...) -> Int

