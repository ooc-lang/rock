include sys/types, sys/stat, unistd
include fcntl

import unistd

open:  extern func(CString, Int) -> Int
write: extern func(FileDescriptor, Pointer, Int) -> Int
read:  extern func(FileDescriptor, Pointer, Int) -> Int
close: extern func(FileDescriptor) -> Int

STDIN_FILENO : extern FileDescriptor
STDOUT_FILENO: extern FileDescriptor
STDERR_FILENO: extern FileDescriptor

FileDescriptor: cover from Int {

    write: func(data: Pointer, len: Int) -> Int{
        result := write(this, data, len)
        //_errMsg(result, "write")
        return result
    }

    write: func ~string (str: String) -> Int {
        write(str, str length())
    }

    read: func ~toBuf (buf: Pointer, len: Int) -> Int {
        read(this, buf, len)
    }

    read: func ~evilAlloc (len: Int) -> Pointer {
        buf := gc_malloc(len)
        read(buf, len) // todo: check errors
        return buf
    }

    close: func() -> Int{
        result := close(this)
        //_errMsg(result, "close")
        return result
    }

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
}





