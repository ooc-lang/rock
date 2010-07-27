import io/[Writer, Reader]
import structs/ArrayList
/*
	Multi-Purpose Buffer class. 
	
	since toString simply returns the pointer to the data, it has to be always 
	zero-terminated. this is done automatically by the constructor or append methods.
	however, when direct resizing of the allocated data buffer via checkLength or
	manipulation of data's memory is done, this should be considered.
	
	*/
 
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
    
    /**
    	reads a whole file into buffer, binary mode
    */
	fromFile: func (fileName: String) -> Bool {
		STEP_SIZE : SizeT = 4096				
		file := FStream open(fileName, "rb")
		if (!file || file error()) return false
		len := file size()
		checkLength(len + 1)	
		data[len] = '\0'
		offset :SizeT= 0
		while (len / STEP_SIZE > 0) {
			retv := file read((data as Char* + offset) as Pointer, STEP_SIZE)
			if (retv != STEP_SIZE || file error()) {
				file close()
				return false
			}	
			len -= retv
			offset += retv
		}
		if (len) file read((data as Char* + offset) as Pointer, len)	
		size += len	
		return (file error()==0) && (file close() == 0)
	}
	
	toFile: func (fileName: String) -> Bool {
		toFile(fileName, false)
	}
	/**
		writes the whole data to a file in binary mode
	*/
	toFile: func ~withAppend (fileName: String, doAppend: Bool) -> Bool {
		STEP_SIZE : SizeT = 4096				
		file := FStream open(fileName, doAppend ? "ab" : "wb") 
		if (!file || file error()) return false
		offset :SizeT = 0
		togo := size
		while (togo / STEP_SIZE > 0) {
			retv := file write ((data as Char* + offset) as String, STEP_SIZE)
			if (retv != STEP_SIZE || file error()) {
				file close()
				return false
			}	
			togo -= retv
			offset  += retv			
		}
		if (togo) file write((data as Char* + offset) as String, togo)	
		return (file error() == 0) && (file close()==0 )					
	}
	
	/**
		calls find with searchCaseSenitive set to true by default 
	*/
	find : func (what: This, offset: SSizeT) -> SSizeT {	
		find(what, offset, true)
	}
	
	/**
		returns -1 when not found, otherwise the position of the first occurence of "what"
		use offset 0 for a new search, then increase it by the last found position +1
		look at implementation of findAll() for an example
	*/	
	find : func ~withCase (what: This, offset: SSizeT, searchCaseSensitive : Bool) -> SSizeT {	
		if (offset >= size || offset < 0) return -1
				
		maxpos : SSizeT = size - what size // need a signed type here		
		if ((maxpos) < 0) return -1
		
		found : Bool				
		sstart := offset 
		
		
		while (sstart <= maxpos) {
			found = true
			for (j in 0..(what size)) {
				if (searchCaseSensitive) {
					if ( (data as Char* + sstart + j)@ != (what data as Char* + j)@ ) {
						found = false
						break
					}				
				} else {
					if ( (data as Char* + sstart + j)@ toUpper() != (what data as Char* + j)@ toUpper() ) {
						found = false
						break
					}				
				}
			}				
			if (found) 	return sstart
			sstart += 1				
		} 			
		return -1
	}

	/**
		returns a list of positions where buffer has been found, or an empty list if not 
	*/
	findAll: func ( what : This) -> ArrayList <SizeT> {
		findAll( what, true) 
	}
	
	/**
		returns a list of positions where buffer has been found, or an empty list if not 
	*/
	findAll: func ~withCase ( what : This, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
		if (what == null || what size == 0) return ArrayList <SizeT> new(0)
		result := ArrayList <SizeT> new (size / what size)
		offset : SSizeT = -1
		while (((offset = find(what, offset + 1, searchCaseSensitive)) != -1)) result add (offset)
		return result	
	}
	
	replaceAll: func ~str (what, whit : String) -> This {
		return replaceAll ( what, what length(), whit, whit length() )
	}
	
	replaceAll: func ~strWithLength (what:String, whatLength: SizeT, whit : String, whitLength: SizeT) -> This {
		return replaceAll (Buffer new ( what, whatLength), Buffer new ( whit, whitLength ) )
	}
	
	replaceAll: func ~buf (what, whit : This) -> This {
		return replaceAll(what, whit, true);
	}	
	
	replaceAll: func ~bufWithCase (what, whit : This, searchCaseSensitive: Bool) -> This {
		if (what == null || what size == 0 || whit == null) return clone()
			
		l := findAll( what, searchCaseSensitive )
		 
		if (l == null || l size() == 0) return clone()
		newlen: SizeT = size + (whit size * l size) - (what size * l size)
		result := This new( newlen + 1)
		result size = newlen
		
		sstart: SizeT = 0 //source (this) start pos
		rstart: SizeT = 0 //result start pos 
		
		for (item in l) {
			
			sdist := item - sstart // bytes to copy
			memcpy(result data as Char* + rstart, data as Char* + sstart, sdist)	
			sstart += sdist		
			rstart += sdist
			memcpy(result data as Char* + rstart, whit data as Char*, whit size)
			sstart += what size
			rstart += whit size 	
			
		}	
		// copy remaining last piece of source	
		sdist := size - sstart
		memcpy(result data as Char* + rstart, data as Char* + sstart, sdist + 1)	// +1 to copy the trailing zero as well
		return result
		
	}
	
	split: func ~str (delimiter: String) -> ArrayList <This> {
		return split( delimiter, delimiter length() )
	}

	split: func ~strWithLength (delimiter: String, length: SizeT) -> ArrayList <This> {
		return split( This new ( delimiter, length ) )
	}
	
	split: func ~buf (delimiter:Buffer) -> ArrayList <This> {
		
		l := findAll(delimiter, true) 
		result := ArrayList <This> new(l size()) 
		sstart: SizeT = 0 //source (this) start pos
		for (item in l) {
			sdist := item - sstart // bytes to copy
			b := This new ((data as Char* + sstart) as String, sdist)
			result add ( b ) 
			sstart += sdist + delimiter size
		}
		sdist := size - sstart // bytes to copy
		b := This new ((data as Char* + sstart) as String, sdist)
		result add ( b ) 		
		return result
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

    /* 	check out the Writer writef method for a simple varargs usage, 
    	this version here is mostly for internal usage (it is called by writef) 
    	*/
    vwritef: func(fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt, list2)        
        va_end (list2)
        
        buffer checkLength( buffer size + length + 1)                
        vsnprintf(buffer data as Char* + buffer size, length + 1, fmt, list)
                
        buffer size += length
        buffer data[buffer size] = '\0'
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

operator == (a, b: Buffer) -> Bool { 
	if (!a && !b) return true
	if ((!a && b) || (!b && a)) return false
	return ( (a size == b size) && 	( memcmp ( a data as Char*, b data as Char*, a size ) == 0 ) )  
}

operator != (a, b: Buffer) -> Bool {
	if (a == b) return false 
	else return true
}
