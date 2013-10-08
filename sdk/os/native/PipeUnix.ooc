import ../[unistd, FileDescriptor, Pipe]

version(unix || apple) {

/**
 * Unix implementation of pipes.
 */
PipeUnix: class extends Pipe {

    readFD, writeFD: FileDescriptor

    init: func ~withFDs (=readFD, =writeFD) {
        if(readFD == -1 && writeFD == -1) {
            init()
            return
        }

        if(readFD == -1) {
            fds := [-1] as Int*

            pipe(fds)
            this readFD = fds[0]
            if (pipe(fds) < 0) {
                // TODO: add detailed error message
                Exception new(This, "Couldn't create pipe") throw()
            }
        }
        if(writeFD == -1) {
            fds := [-1] as Int*

            pipe(fds)
            this writeFD = fds[0]
            if (pipe(fds) < 0) {
                // TODO: add detailed error message
                Exception new(This, "Couldn't create pipe") throw()
            }
        }
    }

    init: func ~twos {
        fds := [-1, -1] as Int*

        /* Try to open a new pipe */
        if (pipe(fds) < 0) {
            // TODO: add detailed error message
            Exception new(This, "Couldn't create pipes") throw()
        }
        readFD  = fds[0]
        writeFD = fds[1]
    }

    read: func ~cstring (buf: CString, len: Int) -> Int {
        howmuch := readFD read(buf, len)
        if (howmuch <= 0) {
            if (errno == EAGAIN) {
                return 0
            }

            eof = true
            return -1
        }
        howmuch
    }

    /** write 'len' bytes of 'data' to the pipe */
    write: func(data: Pointer, len: Int) -> Int {
        return writeFD write(data, len)
    }

    /**
     * close the pipe, either in reading or writing
     * @param arg 'r' = close in reading, 'w' = close in writing
     */
    close: func (end: Char) -> Int {
        fd := _getFD(end)
        if (fd == 0) return 0
        fd close()
    }

    close: func ~both {
        readFD close()
        writeFD close()
    }

    setNonBlocking: func (end: Char) {
        fd := _getFD(end)
        if (fd == 0) return
        fd setNonBlocking()
    }

    setBlocking: func (end: Char) {
        fd := _getFD(end)
        if (fd == 0) return
        fd setBlocking()
    }

    // utility functions

    _getFD: func (end: Char) -> FileDescriptor {
        match end {
            case 'r' => readFD
            case 'w' => writeFD
            case => 0 as FileDescriptor
        }
    }
}

/* C interface */

include fcntl
include sys/stat
include sys/types

EAGAIN: extern Int

}
