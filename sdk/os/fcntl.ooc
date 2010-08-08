include fcntl

FileDescriptor: cover from Int


close: extern func(FileDescriptor) -> Int
open: extern func(Char*, Int) -> FileDescriptor
read: extern func(FileDescriptor, Pointer, Int) -> Int
write: extern func(FileDescriptor, Pointer, Int) -> Int

