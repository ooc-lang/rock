import native/[PipeUnix, PipeWin32]

Pipe: abstract class {

    eof := false

    new: static func -> This {
        version(unix || apple) {
            return PipeUnix new() as This
        }
        version(windows) {
            return PipeWin32 new() as This
        }
        Exception new(This, "Unsupported platform!\n") throw()
        null
    }

    /** read a single byte */
    read: func ~char -> Char {
        c: Char
        howmuch := read(c& as CString, 1)
        
        if (howmuch == -1) return '\0'
        c
    }

    /** read 'len' bytes at most from the pipe */
    read: func ~string (len: Int) -> String {
        buf := gc_malloc(len + 1) as CString
        howmuch := read(buf, len)

        if (howmuch == -1) return null // eof!

        // make sure it's 0-terminated
        buf[howmuch] = '\0'
        return buf toString()
    }

    /** attempt to read a buffer-full */
    read: func ~buffer (buf: Buffer) -> Int {
        bytesRead := read(buf data, buf capacity)
        if (bytesRead >= 0) {
            buf setLength(bytesRead)
        }
        bytesRead
    }

    /** read max len bytes into buf, return number of bytes read, -1 on eof */
    read: abstract func ~cstring (buf: CString, len: Int) -> Int

    /** write a string to the pipe */
    write: func ~string (str: String) -> Int {
        write(str toCString(), str length())
    }

    /** write 'len' bytes of 'data' to the pipe */
    write: abstract func(data: Pointer, len: Int) -> Int

    /**
     * close the pipe, either in reading or writing
     * @param arg 'r' = close in reading, 'w' = close in writing
     */
    close: abstract func (mode: Char) -> Int

    /**
     * Close both ends of the pipe
     */
    close: abstract func ~both

    /**
     * Switch this pipe to non-blocking mode
     */
    setNonBlocking: func

    eof?: func -> Bool {
        eof
    }

}
