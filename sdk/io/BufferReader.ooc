import io/Reader

/**
 * Implement the Reader interface for Buffer.
 */
BufferReader: class extends Reader {
    buffer: Buffer

    init: func ~withBuffer (=buffer) {}

    close: func {
        // nothing to close.
    }

    read: func (dest: Char*, destOffset: Int, maxRead: Int) -> SizeT {
        if (marker >= buffer size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }

        copySize := (marker + maxRead > buffer size ? buffer size - marker : maxRead)
        memcpy(dest, buffer data + marker, copySize)
        marker += copySize
        
        copySize
    }

    peek: func -> Char {
        buffer get(marker)
    }

    read: func ~char -> Char {
        c := buffer get(marker)
        marker += 1
        c
    }

    hasNext?: func -> Bool {
        return marker < buffer size
    }

    seek: func (offset: Long, mode: SeekMode) -> Bool {
        match mode {
            case SeekMode SET =>
                marker = offset
            case SeekMode CUR =>
                marker += offset
            case SeekMode END =>
                marker = buffer size + offset
        }
        _clampMarker()
        true
    }

    _clampMarker: func {
        if (marker < 0) {
            marker = 0
        }

        if (marker >= buffer size) {
            marker = buffer size - 1
        }
    }

    mark: func -> Long {
        return marker
    }
}

