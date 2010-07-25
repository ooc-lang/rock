import io/[Writer, Reader]

Buffer: class {
    size: SizeT
    capacity: SizeT
    data: Char*

    init: func {
        init(128)
    }

    init: func ~withCapa (=capacity) {    	
        capacity += 1
        data = gc_malloc(capacity)
        data[capacity-1] = '\0'        
        size = 0
    }

    init: func ~str (str: String) {
    	init ( str, str length() )
    }

    init: func ~strWithLength (str: String, length: SizeT) {
        init ( length ) // sets trailing \0 as well
        memcpy(data as Char*, str as Char*, length)
        size = length
    }
    
	clone: func -> This {
		result := This new (size) 
		memcpy(result data as Char*, data as Char*, size)
		result size = size
		return result
    } 
    
    append: func ~str (str: String) {
        append(str, str length())
    }

    append: func ~strWithLength (str: String, length: SizeT) {
        checkLength(size + length + 1)
        memcpy(data as Char* + size, str as Char*, length)
        size += length
        data[size] = '\0'
    }

    append: func ~chr (chr: Char) {
        checkLength(size + 2)
        data[size] = chr
        size += 1
        data[size] = '\0'
    }

    get: func ~strWithLengthOffset (str: Char*, offset: SizeT, length: SizeT) -> Int {
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

        memcpy(str, (data as Char*) + offset, copySize)
        copySize
    }

    get: func ~chr (offset: Int) -> Char {
        if(offset >= size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }
        return data[offset]
    }

    // attention: be sure when you call checkLength manually, to apply a trailing '\0' afterwards, as demonstrated in init
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
        return data as String
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

    vwritef: func(fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt, list2)        
        va_end (list2)
        
        buffer checkLength( buffer size + length )                
        vsnprintf(buffer data as Char* + buffer size, length + 1, fmt, list)
        
        buffer size += length
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

    close: func {
        /* nothing to close. */
    }

    read: func(chars: String, offset: Int, count: Int) -> SizeT {
        copySize := buffer get(chars as Char* + offset, marker, count)
        marker += copySize
        return copySize
    }

    read: func ~char -> Char {
        c := buffer get(marker)
        marker += 1
        return c
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

    reset: func(marker: Long) {
        this marker = marker
    }
}
