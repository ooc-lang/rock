import io/Writer

/**
 * Implement the Writer interface for Writer
 */
BufferWriter: class extends Writer {

    buffer: Buffer

    init: func {
        buffer = Buffer new(1024)
    }

    init: func ~withBuffer (=buffer) {}

    buffer: func -> Buffer {
        return buffer
    }

    close: func {
        /* do nothing. */
    }

    write: func ~chr (chr: Char) {
        buffer append(chr)
    }

    write: func (chars: Char*, length: SizeT) -> SizeT {
        buffer append(chars, length)
        length
    }

    /* check out the Writer writef method for a simple varargs usage,
       this version here is mostly for internal usage (it is called by writef)
     */
    vwritef: func(fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt, list2)
        va_end (list2)

        origSize := buffer size
        buffer setLength(origSize + length)
        vsnprintf(buffer data + origSize, length + 1, fmt, list)
    }

}
