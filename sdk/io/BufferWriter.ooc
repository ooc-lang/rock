import io/Writer

/**
 * Implement the Writer interface for Writer
 */
BufferWriter: class extends Writer {

    buffer: Buffer
    pos: Long

    init: func {
        buffer = Buffer new(1024)
        pos = 0
    }

    init: func ~withBuffer (=buffer)

    close: func {
        /* do nothing. */
    }

    _makeRoom: func (len: Long) {
        // re-allocate if needed...
        if (buffer capacity < len) {
            buffer setCapacity(len * 2)
        }
        // and keep buffer length up to date
        if (buffer size < len) {
            buffer size = len
        }
    }

    write: func ~chr (chr: Char) {
        _makeRoom(pos + 1)
        buffer data[pos] = chr
        pos += 1
    }

    mark: func -> Long {
        pos
    }

    seek: func (p: Long) {
        if(p < 0 || p > buffer size) {
            Exception new("Seeking out of bounds! p = %d, size = %d" format(p, buffer size)) throw()
        }
        pos = p
    }

    write: func (chars: Char*, length: SizeT) -> SizeT {
        _makeRoom(pos + length)
        memcpy(buffer data + pos, chars, length)
        pos += length
        length
    }

    /* check out the Writer writef method for a simple varargs usage,
       this version here is mostly for internal usage (it is called by writef)
     */
    vwritef: func (fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt, list2)
        va_end(list2)

        _makeRoom(pos + length + 1)
        vsnprintf(buffer data + pos, length + 1, fmt, list)
        pos += length
    }

}
