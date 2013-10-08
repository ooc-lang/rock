include sys/types, sys/stat, unistd
include fcntl

import unistd

open: extern func(CString, Int) -> Int

PIPE_BUF: extern Int
STDIN_FILENO : extern FileDescriptor
STDOUT_FILENO: extern FileDescriptor
STDERR_FILENO: extern FileDescriptor

// FIXME deprecated ? looks like an ancestor of File

FileDescriptor: cover from Int {

    write: func ~string (str: String) -> Int {
        write(str toCString(), str size)
    }

    read: func ~evilAlloc (len: Int) -> Pointer {
        buf := gc_malloc(len)
        read(buf, len) // todo: check errors
        return buf
    }

    write: extern(write) func(Pointer, Int) -> Int
    read:  extern(read) func(Pointer, Int) -> Int
    close: extern(close) func -> Int
    /*
    dup2: func(fd: FileDescriptor) -> FileDescriptor {
        return dup2(This, fd)
    }
    */

    _errMsg: func(var: Int, funcName: String) {
        if (var < 0) {
            printf("Error in FileDescriptor : %s\n", funcName toCString())
        }
    }

    setNonBlocking: func {
        version (unix || apple) {
            flags := fcntl(this, F_GETFL, 0)
            flags |= O_NONBLOCK
            fcntl(this, F_SETFL, flags)
        }
    }

    setBlocking: func {
        version (unix || apple) {
            flags := fcntl(this, F_GETFL, 0)
            flags &= ~O_NONBLOCK
            fcntl(this, F_SETFL, flags)
        }
    }
}

version (unix || apple) {
    F_SETFL, F_GETFL: extern Int
    O_NONBLOCK: extern Int

    fcntl: extern func (FileDescriptor, Int, Int) -> Int
}

