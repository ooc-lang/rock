import native/[PipeUnix, PipeWin32]

Pipe: abstract class {

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

    /** read 'len' bytes at most from the pipe */
    read: abstract func(len: Int) -> Pointer

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
    close: abstract func(mode: Char) -> Int

}
