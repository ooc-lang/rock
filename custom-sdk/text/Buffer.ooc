import io/[Writer, Reader]

Buffer: class {
    size: SizeT
    capacity: SizeT
    data: String

    init: func {
        init(128)
    }

    init: func ~withCapa (=capacity) {
        data = gc_malloc(capacity)
        size = 0
    }

    init: func ~withContent (.data) {
        this data = data clone()
        size = data length()
        capacity = data length()
    }

    append: func ~str (str: String) {
        length := str length()
        append(str, length)
    }

    append: func ~strWithLength (str: String, length: SizeT) {
        checkLength(size + length)
        memcpy(data as Char* + size, str as Char*, length)
        size += length
    }
 
    append: func ~chr (chr: Char) {
        checkLength(size + 1)
        data[size] = chr
        size += 1
    }

    get: func ~strWithLengthOffset (dest: Char*, offset: SizeT, length: SizeT) {
        if(offset >= size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }

        copySize: Int
        if((offset + length) > size) {
            copySize = size - offset
        }
        else {
            copySize = length
        }

        memcpy(dest, (data as Char*) + offset, copySize)
    }

    get: func ~chr (offset: Int) -> Char {
        if(offset >= size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }
        return data[offset]
    }
    
    checkLength: func (min: SizeT) {
        if(min >= capacity) {
            newCapa := min * 1.2 + 10
            tmp := gc_realloc(data, newCapa)
            if(!tmp) {
                Exception new(This, "Couldn't allocate enough memory for Buffer to grow to capacity "+newCapa) throw()
            }
            data = tmp
            capacity = newCapa
        }
    }
    
    toString: func -> String {
        checkLength(size + 1)
        data[size] = '\0'
        return data // ugly hack. or is it?
    }
}

/**
 * This deprecates and replaces StringBuffer
 */
BufferWriter: class extends Writer {
    
    buffer: Buffer

    init: func {
        buffer = Buffer new()
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

    write: func (chars: String, length: SizeT) -> SizeT {
        buffer append(chars, length)
        return length
    }
}

BufferReader: class extends Reader {
    buffer: Buffer

    init: func {
        buffer = Buffer new()
    }

    init: func ~withBuffer (=buffer) {}

    buffer: func -> Buffer {
        return buffer
    }

    read: func(chars: String, offset: Int, count: Int) -> SizeT {
        buffer get(chars as Char* + offset, marker, count)
        marker += count
        return count
    }

    read: func ~char -> Char {
        c := buffer get(marker)
        marker += 1
        return c
    }

    hasNext: func -> Bool {
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

    reset: func(marker: Long) {
        this marker = marker
    }
}
