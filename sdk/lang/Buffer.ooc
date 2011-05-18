import structs/ArrayList

/**
 * A Buffer is a mutable string of characters.
 *
 * When building a string incrementally, with multiple appends, it's best
 * to use Buffer instead of String, to avoid unnecessary allocation
 *
 * @author rofl0r
 * @author Amos Wenger (nddrylliog)
 */
Buffer: class extends Iterable<Char> {
    
    /** size of the buffer, in bytes, e.g. how much bytes do we store currently */
    size: SizeT

    /** capacity of the buffer, in bytes, e.g. how much bytes we can store before resizing. */
    capacity: SizeT

    /**
     * Original pointer to the allocated memory - a reference is kept here
     * so that it doesn't get collected by the Garbage Collector when we shift the pointer.
     * Shifting the data pointer is done in trimLeft so we don't have to memcpy all the
     * bytes to the left.
     */
    mallocAddr: Char*

    /** Data bytes, this must be passed to C functions expecting char* */
    data: Char*

    _rshift: func -> SizeT { return mallocAddr == null || data == null ? 0 :  (data as SizeT - mallocAddr as SizeT) as SizeT}

    /* used to overwrite the data/attributes of *this* with that of another This */
    setBuffer: func(newOne: This) {
        data = newOne data
        mallocAddr = newOne mallocAddr
        capacity = newOne capacity
        size = newOne size
    }

    /**
     * Create a new, empty buffer with an 1KB capacity
     */
    init: func ~empty {
        init(1024)
    }

    /**
     * Create a new, empty buffer that can hold 'capacity' bytes before being resized.
     */
    init: func (capacity: SizeT) {
        setCapacity(capacity)
    }

    /**
     * Create a new String from a zero-terminated C String with known length
     * optional flag for stringliteral initializaion with zero copying
     */
    init: func ~cStrWithLength(s: CString, length: SizeT, stringLiteral? := false) {
        if(stringLiteral?) {
            data = s
            size = length
            mallocAddr = null
            capacity = 0
        } else {
    	    setLength(length)
	        memcpy(data, s, length) 
        }        
    }

    /**
     * @return the number of characters in this String
     */
    length: func -> SizeT { size }

    /**
     * Adjust this buffer's capacity, reallocate memory if needed.
     *
     * @param newCapacity The number of bytes (not characters) this buffer
     * should be capable of storing
     */
    setCapacity: func (newCapacity: SizeT) {
        rshift := _rshift()
        min := newCapacity + 1 + rshift
        
        if(min >= capacity) {
            // allocate 20% + 10 bytes more than needed - just in case
            capacity = (min * 120) / 100 + 10
            
            // align at 8 byte boundary for performance
            al := 8 - (capacity % 8)
            if (al < 8) capacity += al

            rs := rshift
            if (rs) shiftLeft(rs)
            
            tmp := gc_realloc(mallocAddr, capacity)
            if(!tmp) OutOfMemoryException new(This) throw()
            
            // if we were coming from a string literal, copy the original data as well (gc_realloc cant work on text segment)
            if(size > 0 && mallocAddr == null) {
            	rs = 0
            	memcpy(tmp, data, size)
            }

            mallocAddr = tmp
            data = tmp
            if (rs) shiftRight(rs)
        }
        // just to be sure to be always zero terminated
        data[newCapacity] = '\0'
    }

    /** sets capacity and size flag, and a zero termination */
    setLength: func (newLength: SizeT) {
        if(newLength != size) {
            if(newLength > capacity) {
                setCapacity(newLength)
            }
            size = newLength
            data[size] = '\0'
        }
    }

    /* does a strlen on the buffers data and sets this as the size
        call only when you're sure that the data is zero terminated
        only needed when you pass the data to some extern function, and don't how many bytes it wrote.
     */
    sizeFromData: func {
        setLength(data as CString length())
    }

    /*  shifts data pointer to the right count bytes if possible
        if count is bigger as possible shifts right maximum possible
        size and capacity is decreased accordingly  */
    // remark: can be called with negative value (done by leftShift)
    shiftRight: func (count: SSizeT) {
        if (count == 0 || size == 0) return
        c := count
        rshift := _rshift()
        if (c > size) c = size
        else if (c < 0 && c abs() > rshift) c = rshift *-1
        data += c
        size -= c
    }

    /* shifts back count bytes, only possible if shifted right before */
    shiftLeft: func (count : SSizeT) {
        if (count != 0) shiftRight (-count) // it can be so easy
    }

    /** return a copy of *this*. */
    clone: func -> This {
        clone(size)
    }

    clone: func ~withMinimum (minimumLength := size) -> This {
        newCapa := minimumLength > size ? minimumLength : size
        copy := new(newCapa)
        //"Cloning %s, new capa %zd, new size %zd" printfln(data, newCapa, size)
        copy size = size
        memcpy(copy data, data, size)
        copy
    }

    substring: func ~tillEnd (start: SizeT) {
        substring(start, size)
    }

    /** *this* will be reduced to the characters in the range ``start..end``
    	The substring begins at the specified start and extends to the character at index end - 1.
    	So the length of the substring is end-start */
    substring: func (start: SSizeT, end: SSizeT) {
		if(start < 0) start += size + 1
		if(end < 0) end += size + 1
		if(end != size) setLength(end)
		if(start > 0) shiftRight(start)
	}

    /** return a This that contains *this*, repeated *count* times. */
    times: func (count: SizeT) {
        origSize := size
        setLength(size * count)
        for(i in 1..count) { // we start at 1, since the 0 entry is already there
            memcpy(data + (i * origSize), data, origSize)
        }
    }

    append: func ~buf(other: This) {
        if(!other) return
        append~pointer(other data, other size)
    }

    append: func ~str(other: String) {
        if(!other) return
        append~buf(other _buffer)
    }

    /** appends *other* to *this* */
    append: func ~pointer (other: Char*, otherLength: SizeT) {
        origlen := size
        //"appending `" print()
        //fwrite(other, 1, otherLength, stdout)
        //"` to `%s`, new length = %zd" printfln(data, size + otherLength)
        
        setLength(size + otherLength)
        memcpy(data + origlen, other, otherLength)
    }

    /** appends a char to either *this* or a clone*/
    append: func ~char (other: Char)  {
        append(other&, 1)
    }

    /** prepends *other* to *this*. */
    prepend: func ~buf (other: This) {
        prepend(other data, other size)
    }

    prepend: func ~str (other: String) {
        prepend(other _buffer)
    }

    /** return a new string containg *other* followed by *this*. */
    prepend: func ~pointer (other: Char*, otherLength: SizeT) {
        if (_rshift() < otherLength) {
            newthis := This new (size + otherLength)
            memcpy(newthis data, other, otherLength)
            memcpy(newthis data + otherLength, data, size)
            setBuffer(newthis)
        } else {
            // seems we have enough room on the left
            shiftLeft(otherLength)
            memcpy(data , other, otherLength)
        }
    }

    /** replace *this* or a clone with  *other* followed by *this*. */
    prepend: func ~char (other: Char) {
        prepend(other&, 1)
    }

    /** @return true if the string is empty */
    empty?: func -> Bool {
        size == 0
    }

    /** compare *length* characters of *this* with *other*, starting at *start*.
        Return true if the two strings are equal, return false if they are not. */
    compare: func (other: This, start, length: SSizeT) -> Bool {
        //"comparing %s and %s, start = %zd, length = %zd, size = %zd, start + length = %zd" printfln(data, other data, start, length, size, start + length)
        if (size < (start + length) || other size < length) return false
        
        for(i in 0..length) {
            if(data[start + i] != other[i]) {
                return false
            }
        }
        true
    }

    /** return true if *other* and *this* are equal (in terms of being null / having same size and content). */
    equals?: final func (other: This) -> Bool {
        //"equaling %s and %s, size = %zd, other size = %zd" printfln(data, other data, size, other size)
        if ((this == null) || (other == null)) return false
        if(other size != size) return false
        compare(other, 0, size)
    }

    /** @return true if the first characters of *this* are equal to *s*. */
    startsWith?: func (s: This) -> Bool {
        len := s length()
        if (size < len) return false
        compare(s, 0, len)
    }

    /** @return true if the first character of *this* is equal to *c*. */
    startsWith?: func ~char (c: Char) -> Bool {
        (size > 0) && (data[0] == c)
    }

    /** @return true if the last characters of *this* are equal to *s*. */
    endsWith?: func (s: This) -> Bool {
        len := s size
        if (size < len) return false
        compare(s, size - len, len)
    }

    /** @return true if the last character of *this* is equal to *c*. */
    endsWith?: func ~char(c: Char) -> Bool {
        (size > 0) && data[size] == c
    }

    find: func ~char (what: Char, offset: SSizeT, searchCaseSensitive := true) -> SSizeT {
        find (what&, 1, offset, searchCaseSensitive)
    }

    /**
        returns -1 when not found, otherwise the position of the first occurence of "what"
        use offset 0 for a new search, then increase it by the last found position +1
        look at implementation of findAll() for an example
    */
    find: func (what: This, offset: SSizeT, searchCaseSensitive := true) -> SSizeT {
        find~pointer(what data, what size, offset, searchCaseSensitive)
    }

    find: func ~pointer (what: Char*, whatSize: SizeT, offset: SSizeT, searchCaseSensitive := true) -> SSizeT {
        if (offset >= size || offset < 0 || what == null || whatSize == 0) return -1

        maxpos : SSizeT = size - whatSize // need a signed type here
        if (maxpos < 0) return -1

        found : Bool
        sstart := offset

        for (sstart in offset..(maxpos + 1)) {
            found = true
            for (j in 0..whatSize) {
                if (searchCaseSensitive) {
                    if (data[sstart + j] != what[j] ) {
                        found = false
                        break
                    }
                } else {
                    if (data[sstart + j] toUpper() != what[j] toUpper()) {
                        found = false
                        break
                    }
                }
            }
            if (found) return sstart
        }
        -1
    }

    /** returns a list of positions where buffer has been found, or an empty list if not  */
    findAll: func ~withCase ( what : This, searchCaseSensitive := true) -> ArrayList <SizeT> {
        findAll(what data, what size, searchCaseSensitive)
    }

    findAll: func ~pointer ( what : Char*, whatSize: SizeT, searchCaseSensitive := true) -> ArrayList <SizeT> {
        if (what == null || whatSize == 0) return ArrayList <SizeT> new(0)
        result := ArrayList <SizeT> new (size / whatSize)
        offset : SSizeT = (whatSize ) * -1
        while (((offset = find(what, whatSize, offset + whatSize, searchCaseSensitive)) != -1)) result add (offset)
        result
    }

    replaceAll: func ~buf (what, whit: This, searchCaseSensitive := true) {
        findResults := findAll(what, searchCaseSensitive)
        if (findResults == null || findResults size == 0) return
        
        newlen: SizeT = size + (whit size * findResults size) - (what size * findResults size)
        result := new(newlen)
        result setLength(newlen)

        sstart: SizeT = 0 // source (this) start pos
        rstart: SizeT = 0 // result start pos

        for (item in findResults) {
            sdist := item - sstart // bytes to copy
            memcpy(result data + rstart, data + sstart, sdist)
            sstart += sdist
            rstart += sdist
            
            memcpy(result data + rstart, whit data, whit size)
            sstart += what size
            rstart += whit size

        }
        // copy remaining last piece of source
        sdist := size - sstart
        memcpy(result data + rstart, data  + sstart, sdist + 1) // +1 to copy the trailing zero as well
        setBuffer(result)
    }

    /** replace all occurences of *oldie* with *kiddo* in place/ in a clone, if immutable is set */
    replaceAll: func ~char (oldie, kiddo: Char) {
        for(i in 0..size) {
            if(data[i] == oldie) data[i] = kiddo
        }
    }
    
    /** Transform all characters according to a transformation function */
    map: func (f: Func (Char) -> Char) {
        for(i in 0..size) {
            data[i] = f(data[i])
        }
    }

    /**
     * Converts all of the characters in this Buffer to lower case.
     */
    toLower: func {
        for(i in 0..size) {
            data[i] = data[i] toLower()
        }
    }

    /**
     * Converts all of the characters in this Buffer to lower case.
     */
    toUpper: func {
        for(i in 0..size) {
            data[i] = data[i] toUpper()
        }
    }

    /**
     * Convert this buffer to an immutable String
     */
    toString: func -> String { String new(this) }

    /** return the index of *c*, but only check characters ``start..length``.
        However, the return value is the index of the *c* relative to the
        string's beginning. If *this* does not contain *c*, return -1. */
    indexOf: func ~char (c: Char, start: SSizeT = 0) -> SSizeT {
        for(i in start..size) {
            if((data + i)@ == c) return i
        }
        return -1
    }

    /** return the index of *s*, but only check characters ``start..length``.
        However, the return value is relative to the *this*' first character.
        If *this* does not contain *c*, return -1. */
    indexOf: func ~buf (s: This, start: SSizeT = 0) -> SSizeT {
        return find(s, start, false)
    }


    /** return *true* if *this* contains the character *c* */
    contains?: func ~char (c: Char) -> Bool { indexOf(c) != -1 }

    /** return *true* if *this* contains the string *s* */
    contains?: func ~buf (s: This) -> Bool { indexOf(s) != -1 }

    trim: func~pointer(s: Char*, sLength: SizeT) {
        trimRight(s, sLength)
        trimLeft(s, sLength)
    }

    trim: func ~buf(s : This) {
        trim(s data, s size)
    }

    /** *c* characters stripped at both ends. */
    trim: func ~char (c: Char) {
        trim(c&, 1)
    }

    /** whitespace characters (space, CR, LF, tab) stripped at both ends. */
    trim: func ~whitespace {
        trim(" \r\n\t" toCString(), 4)
    }

    /** space characters (ASCII 32) stripped from the left side. */
    trimLeft: func ~space {
        trimLeft(' ')
    }

    /** *c* character stripped from the left side. */
    trimLeft: func ~char (c: Char) {
        trimLeft(c&, 1)
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~buf (s: This) {
        trimLeft(s data, s size)
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~pointer (s: Char*, sLength: SizeT) {
        if (size == 0 || sLength == 0) return
        start : SizeT = 0
        while (start < size && (data + start)@ containedIn?(s, sLength) ) start += 1
        if(start == 0) return
        shiftRight( start )
    }

    /** space characters (ASCII 32) stripped from the right side. */
    trimRight: func ~space { trimRight(' ') }

    /** *c* characters stripped from the right side. */
    trimRight: func ~char (c: Char) {
        trimRight(c&, 1)
    }

    /** *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~buf (s: This) {
        trimRight(s data, s size)
    }

    /**
     * @return (a copy of) *this* with all characters contained by *s* stripped from the right side
     */
    trimRight: func ~pointer (s: Char*, sLength: SizeT) {
        end := size
        while(end > 0 && data[end - 1] containedIn?(s, sLength)) {
            end -= 1
        }
        if (end != size) setLength(end);
    }

    /** reverses *this*. "ABBA" -> "ABBA" .no. joke. "ABC" -> "CBA" */
    reverse: func {
        result := this
        bytesLeft := size
        
        i := 0
        while (bytesLeft > 1) {
            c := result data[i]
            result data[i] = result data[size - 1 - i]
            result data[size - 1 - i] = c
            bytesLeft -= 2
            i += 1
        }
    }

    /** return the number of *what*'s occurences in *this*. */
    count: func (what: Char) -> SizeT {
        result : SizeT = 0
        for(i in 0..size) {
            if(data[i] == what) result += 1
        }
        result
    }

    /** return the number of *what*'s non-overlapping occurences in *this*. */
    count: func ~buf (what: This) -> SizeT {
        findAll(what) size
    }

    /** return the index of the last occurence of *c* in *this*.
        If *this* does not contain *c*, return -1. */
    lastIndexOf: func (c: Char) -> SSizeT {
        i : SSizeT = size - 1
        while(i >= 0) {
            if(data[i] == c) return i
            i -= 1
        }
        return -1
    }

    /** print *this* to stdout without a following newline. Flush stdout. */
    print: func {
        fwrite(data, 1, size, stdout)
    }
    
    print: func ~withStream (stream: FStream) {
        fwrite(data, 1, size, stream)
    }

    /** print *this* followed by a newline. */
    println: func {
        print(stdout); '\n' print(stdout)
    }
    
    println: func ~withStream (stream: FStream) {
        print(stream); '\n' print(stream)
    }

    // TODO make these faster by not simply calling the C API.
    // now that we have the length stored we have an advantage

    /** convert the string's contents to Int. */
    toInt: func -> Int                       { strtol(this data, null, 10)   }
    toInt: func ~withBase (base: Int) -> Int { strtol(this data, null, base) }

    /** convert the string's contents to Long. */
    toLong: func -> Long                        { strtol(this data, null, 10)   }
    toLong: func ~withBase (base: Long) -> Long { strtol(this data, null, base) }

    /** convert the string's contents to Long Long. */
    toLLong: func -> LLong                         { strtoll(this data, null, 10)   }
    toLLong: func ~withBase (base: LLong) -> LLong { strtoll(this data, null, base) }

    /** convert the string's contents to Unsigned Long. */
    toULong: func -> ULong                         { strtoul(this data, null, 10)   }
    toULong: func ~withBase (base: ULong) -> ULong { strtoul(this data, null, base) }

    /** convert the string's contents to Float. */
    toFloat: func -> Float                         { strtof(this data, null)   }

    /** convert the string's contents to Double. */
    toDouble: func -> Double                       { strtod(this data, null)   }

    /** convert the string's contents to Long Double. */
    toLDouble: func -> LDouble                     { strtold(this data, null)   }


    iterator: func -> BufferIterator<Char> {
        BufferIterator<Char> new(this)
    }

    forward: func -> BufferIterator<Char> {
        iterator()
    }

    backward: func -> BackIterator<Char> {
        backIterator() reversed()
    }

    backIterator: func -> BufferIterator<Char> {
        iter := BufferIterator<Char> new(this)
        iter i = length()
        return iter
    }

    /**
     * @return the index-th character of this string
     */
    get: func (index: SSizeT) -> Char {
        if(index < 0) index = size + index
        if(index < 0 || index >= size) OutOfBoundsException new(This, index, size) throw()
        data[index]
    }

    /**
     * @return the index-th character of this string
     */
    set: func (index: SSizeT, value: Char) {
        if(index < 0) index = size + index
        if(index < 0 || index >= size) OutOfBoundsException new(This, index, size) throw()
        data[index] = value
    }

    /** @return this buffer, as an UTF8-encoded null-terminated byte array, usable by C functions */
    toCString: func -> CString { data as CString }

}

/* Comparisons */

operator == (buff1, buff2: Buffer) -> Bool {
    buff1 equals?(buff2)
}

operator != (buff1, buff2: Buffer) -> Bool {
    !buff1 equals?(buff2)
}

/* Access and modification */

operator [] (buffer: Buffer, index: SSizeT) -> Char {
    buffer get(index)
}

operator []= (buffer: Buffer, index: SSizeT, value: Char) {
    buffer set(index, value)
}

operator [] (buffer: Buffer, range: Range) -> Buffer {
    b := buffer clone()
    b substring(range min, range max)
    b
}

operator * (buffer: Buffer, count: Int) -> Buffer {
    b := buffer clone(buffer size * count)
    b times(count)
    b
}

operator + (left, right: Buffer) -> Buffer {
    b := left clone(left size + right size)
    b append(right)
    b
}
