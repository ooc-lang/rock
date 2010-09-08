import ../Pipe, native/win32/[types, errors]

version(windows) {

include windows

/** Extern functions */
CreatePipe:    extern func (readPipe: Handle*, writePipe: Handle*, lpPipeAttributes: Pointer, nSize: Long /* DWORD */) -> Bool
ReadFile:      extern func (hFile: Handle, buffer: Pointer, numberOfBytesToRead:  Long, numberOfBytesRead:    Long*, lpOverlapped: Pointer) -> Bool
WriteFile:     extern func (hFile: Handle, buffer: Pointer, numberOfBytesToWrite: Long, numberOfBytesWritten: Long*, lpOverlapped: Pointer) -> Bool
CloseHandle:   extern func (handle: Handle) -> Bool
PeekNamedPipe: extern func (hPipe: Handle, buffer: Pointer, bufferSize: Long, bytesRead: Long*, totalBytesAvail: Long*, bytesLeftThisMessage: Long*) -> Bool

SecurityAttributes: cover from SECURITY_ATTRIBUTES {
    length: extern(nLength) Int
    inheritHandle: extern(bInheritHandle) Bool
    securityDescriptor: extern(lpSecurityDescriptor) Pointer
}

PipeWin32: class extends Pipe {

    readFD = 0, writeFD = 0 : Handle

    init: func ~twos {
        saAttr: SecurityAttributes

        // Set the bInheritHandle flag so pipe handles are inherited.
        saAttr length = SecurityAttributes size
        saAttr inheritHandle = true
        saAttr securityDescriptor = null

        /* Try to open a new pipe */
        if(!CreatePipe(readFD&, writeFD&, saAttr&, 0)) {
            // TODO: add detailed error message
            Exception new(This, "Couldn't create pipes") throw()
        }
    }

    /** read 'len' bytes at most from the pipe */
    read: func(bytesRequested: Int) -> Pointer {
        howmuch: Long

        totalBytesAvail: Long
        if(!PeekNamedPipe(readFD, null, 0, null, totalBytesAvail&, null)) {
            Exception new(This, "Couldn't peek pipe") throw()
        }

        // Don't try to read if there's no bytes ready atm
        if(totalBytesAvail == 0) return null

        // don't request more than there's available
        bytesAsked := totalBytesAvail > bytesRequested ? bytesRequested : totalBytesAvail
        buffer :=  Buffer new(bytesAsked + 1)

        bytesRead: Long
        if(!ReadFile(readFD, buffer data, bytesAsked, bytesRead&, null)) {
            if(GetLastError() == ERROR_HANDLE_EOF) {
                // then it's okay
                return null
            }
            Exception new(This, "Couldn't read pipe") throw()
        }
        buffer setLength(bytesRead)
        return buffer data
    }

    /** write 'len' bytes of 'data' to the pipe */
    write: func(data: Pointer, len: Int) -> Int {
        WriteFile(writeFD, data, len as Long, null, null) == 0 ? 1 : 0
    }

    /**
     * close the pipe, either in reading or writing
     * @param arg 'r' = close in reading, 'w' = close in writing
     */
    close: func(mode: Char) -> Int{
        return match mode {
            case 'r' => CloseHandle(readFD) ? 1 : 0
            case 'w' => CloseHandle(writeFD) ? 1 : 0
            case     => 0
        }
    }
}

}
