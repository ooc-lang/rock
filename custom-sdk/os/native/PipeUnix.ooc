import ../[unistd, FileDescriptor, Pipe]

version(unix || apple) {

include fcntl
include sys/stat
include sys/types

PipeUnix: class extends Pipe {
    
    readFD:  FileDescriptor 
    writeFD: FileDescriptor 

    init: func ~withFDs (=readFD, =writeFD) {
        if(readFD == -1 && writeFD == -1) {
            init()
            return
        }
        
        if(readFD == -1) {
            fds : Int[1]; fds[0] = -1
            pipe(fds)
            this readFD = fds[0]
            if (pipe(fds) < 0) {
                "Error in creating the pipe" println()
            }
        }
        if(writeFD == -1) {
            fds : Int[1]; fds[0] = -1
            pipe(fds)
            this writeFD = fds[0]
            if (pipe(fds) < 0) {
                "Error in creating the pipe" println()
            }
        }
    }
    
    init: func ~twos {
        fds : Int[2]; fds[0] = -1; fds[1] = -1
        /* Try to open a new pipe */
        if (pipe(fds) < 0) {
            "Error in creating the pipes" println()
        }
        readFD  = fds[0]
        writeFD = fds[1]
    }
    
    /** read 'len' bytes at most from the pipe */
    read: func(len: Int) -> Pointer {
        //return readFD read(len)
        buf := String new(len)
        howmuch := read(readFD, buf, len)
        buf[howmuch] = '\0'
        return buf
    }
    
    /** write 'len' bytes of 'data' to the pipe */
    write: func(data: Pointer, len: Int) -> Int{
        return writeFD write(data, len)
    }

    /**
     * close the pipe, either in reading or writing 
     * @param arg 'r' = close in reading, 'w' = close in writing
     */
    close: func(mode: Char) -> Int{
        return match mode {
            case 'r' => readFD close()
            case 'w' => writeFD close()
            case     => -666
        }
    }
}          

}
