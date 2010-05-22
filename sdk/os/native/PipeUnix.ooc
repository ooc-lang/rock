import ../[unistd, FileDescriptor, Pipe]

version(unix || apple) {

include fcntl
include sys/stat
include sys/types

PipeUnix: class extends Pipe {

    readFD, writeFD:  FileDescriptor

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

    /** read 'len' bytes at most from the pipe */
    read: func(len: Int) -> Pointer {
        //return readFD read(len)
        buf := gc_malloc(len + 1)
        howmuch := readFD read(buf, len)
        buf[howmuch] = '\0'
        return buf
    }

    /** write 'len' bytes of 'data' to the pipe */
    write: func(data: Pointer, len: Int) -> Int {
        return writeFD write(data, len)
    }

    /**
     * close the pipe, either in reading or writing
     * @param arg 'r' = close in reading, 'w' = close in writing
     */
    close: func(mode: Char) -> Int {
        return match mode {
            case 'r' => readFD close()
            case 'w' => writeFD close()
            case     => 0
        }
    }
}

}
