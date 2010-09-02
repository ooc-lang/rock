import io/Reader

/**
 * Implement the Reader interface for Buffer.
 */
BufferReader: class extends Reader {
    buffer: Buffer

    init: func ~withBuffer (=buffer) {}

    buffer: func -> Buffer {
        return buffer
    }

    close: func {
        // nothing to close.
    }

    read: func(dest: Char*, destOffset: Int, maxRead: Int) -> SizeT {
        if(marker >= buffer size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }

        copySize := (marker + maxRead > buffer size ? buffer size - marker : maxRead)
        memcpy(dest, buffer data + marker, copySize)
        marker += copySize
        
        copySize
    }

    read: func ~char -> Char {
        c := buffer get(marker)
        marker += 1
        c
    }

    hasNext?: func -> Bool {
        return marker < buffer size
    }

    rewind: func(offset: Int) {
        marker -= offset
        if(marker < 0) {
            marker = 0
        }
    }

    mark: func -> Long {
        return marker
    }

    reset: func(=marker) {}
}

