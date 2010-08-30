import io/[Writer, Reader]
import structs/ArrayList
import text/EscapeSequence

include stdio
cprintf: extern(printf) func(Char*, ...) -> Int

WHITE_SPACE := EscapeSequence unescape(" \r\n\t") toCString()

/**
    Multi-Purpose Buffer class.
    This is the big brother of String, optimized for performance. */

    /*
    since toString simply returns the pointer to the data, it has to be always
    zero-terminated. this is done automatically by the constructor or append methods.
    however, when direct resizing of the allocated data buffer via checkLength or
    manipulation of data's memory is done, this should be considered.
    some methods may look a bit ugly since they're optimized for best possible performance

    */
Buffer: class {
    /*  stores current size of string */
    size: SizeT

    /*  stores count of currently alloced mem */
    capacity: SizeT

    /*  stores the original pointer to the malloc'd mem
        we need that so the GC doesn't accidentally free the mem, when we shift the data pointer */
    /*   shifting of data ptr is used only in combination with shiftRight function
        we use it also for checking if the buffer points to a stringliteral, then it will be null.
        this is mainly used if a trimleft is done, so that we don't have to do lengthy mallocs */
    mallocAddr : Pointer

    /* pointer to the string data's start byte, this must be implicitly passed to functions working with Char* */
    data : Char*

    debug: func { printf ("size: %x. capa: %x. rshift: %x. data: %x. data@: %s\n", size, capacity, _rshift(), data, data) }

    _rshift: func -> SizeT { return mallocAddr == null || data == null ? 0 :  (data as SizeT - mallocAddr as SizeT) as SizeT}

    /* used to overwrite the data/attributes of *this* with that of another This */
    setBuffer: func( newOne : This ) {
        data = newOne data
        mallocAddr = newOne mallocAddr
        capacity = newOne capacity
        size = newOne size
    }

    toCString: inline func -> CString { data as CString }

    init: func ~zero { init(0) }

    /** Create a new string exactly *length* characters long (without the nullbyte).
        Attention! there is a catch: size will not be set, so if you manipulate Buffer data directly, be sure to set the size afterwards!
        This has to be like that so you can i.e. prealloc a new buffer with predetermined size, then append stuff to it
        The contents of the string are undefined.   */
    init: func (capa: SizeT) {
        setCapacity(capa)
    }

    /* same as above, but set Size as well */
    // FIXME on x32 platforms, the above function without suffix is chosen as teh default, thats why i have to add the dummy here to have a different prototype
    init: func ~withSize(sice: SizeT, dummy: Bool) {
        setLength(sice)
    }

    init: func ~withBuffer (str: This) {
        setBuffer(str)
    }

    /** Create a new string of the length 1 containing only the character *c* */
    init: func ~withChar (c: Char) {
        setLength(1)
        data@ = c
    }

    /** create a new String from a zero-terminated C String */
    init: func ~withCStr(s : CString) {
        init (s, s length())
    }

    /** create a new String from a zero-terminated C String with known length */
    // ATTENTION the mangled name of this function is hardcoded in CGenerator.ooc
    // so you'd rather not change it
    init: func ~withCStrAndLength(s : CString, length: SizeT) {
        setLength(length)
        memcpy(data, s, length)
    }

    /* for construction of String/Buffers from a StringLiteral */
    init: func ~stringLiteral(s: CString, length: SizeT, isStringLiteral: Bool) {
        if(isStringLiteral) {
            data = s
            size = length
            mallocAddr = null
            capacity = 0
        } else    raise("optional constant function arguments are not supported yet! otherwise this branch would execute what withCStrAndLength does currently")
    }

    _literal?: inline func -> Bool {
        data != null && mallocAddr == null
    }

    _makeWritable: func {
        _makeWritable(size)
    }

    _makeWritable: func~withCapacity(newSize: SizeT) {
        sizeCp := size
        dataCp := data
        data = null
        size = 0
        capacity = 0
        setCapacity(newSize > sizeCp ? newSize : sizeCp)
        size = sizeCp
        memcpy(data, dataCp, sizeCp)
        (data + sizeCp)@ = '\0'
    }

    init: func ~withStr(s: String) { init~withBuffer( s _buffer) }

    /** return the string's length, excluding the null byte. */
    length: func -> SizeT { size }


    /** sets capacity to a sane amount and (re)allocs the needed memory,size aka length stays untouched */
    setCapacity: func (length: SizeT) {
        /* we do a trick: if length is 0, we'll let it point to capacity
            this way we have a valid zero length, zero terminated string, without using malloc */
        //printf("---------------- sc %d\n", length)
        //debug()
        if (data == null && length == 0 && capacity == 0 && size == 0) {
            data = capacity& as Pointer
            return
        }
        min := length + 1
        min += _rshift()
        if(min >= capacity) {
            // if length was 0 before, reset the data pointer so our trick above works
            if (size == 0 && capacity == 0 && mallocAddr == null && data as Pointer == capacity& as Pointer) data = null
            capacity = (min * 120) / 100 + 10 // let's stay integer, mkay ?
            // align at 8 byte boundary
            al := 8 - (capacity % 8)
            if (al < 8) capacity += al

            rs := _rshift()
            if (rs) shiftLeft( rs )
            tmp := gc_realloc(mallocAddr, capacity)
            if(!tmp) {
                Exception new(This, "Couldn't allocate enough memory for Buffer to grow to capacity " + capacity toString()) throw()
            }

            mallocAddr = tmp
            data = tmp
            if (rs) shiftRight( rs )
        }
        // just to be sure to be always zero terminated
        (data as Char* + length)@ = '\0'
        //debug()
    }

    /** sets capacity and size flag, and a zero termination */
    setLength: func (length: SizeT) {
        //cprintf("setlen called on %d:%p:%s with size %d, literal? %d\n", size, data, data, length, _literal?())
        if(data == null || length != size || (data as Char* + size)@ != '\0') {
            if (_literal?()) {
                _makeWritable(length)
            } else if (length == 0 || length > capacity) { // special case for 0 to have our zero malloc trick work
                setCapacity(length)
            }
            size = length
            (data as Char* + size)@ = '\0'
        }
    }

    /* does a strlen on the buffers data and sets this as the size
        call only when you're sure that the data is zero terminated
        only needed when you pass the data to some extern function, and don't how many bytes it wrote.
     */
    sizeFromData: func {
        assert(data != null)
        setLength(data as CString length())
    }

    /*  shifts data pointer to the right count bytes if possible
        if count is bigger as possible shifts right maximum possible
        size and capacity is decreased accordingly  */

    // remark: can be called with negative value (done by leftShift)
    shiftRight: func ( count: SSizeT ) {
        assert(data != null)
        if (count == 0) return
        if (_literal?()) _makeWritable() // sorry cant allow shifting on literals, since mallocaddr is not set and the bounds can not be checked... or could they? hmm....
        //printf("sR : %d\n", count)
        //debug()
        if (count == 0 || size == 0) return
        c := count
        rshift := _rshift()
        if (c > size) c = size
        else if (c < 0 && c abs() > rshift) c = rshift *-1
        data += c
        size -= c
        //debug()
    }

    /* shifts back count bytes, only possible if shifted right before */
    shiftLeft: func ( count : SSizeT) {
        if (count != 0) shiftRight ( count * -1) // it can be so easy
    }

    /** return true if *other* and *this* are equal (in terms of being null / having same size and content). */
    equals?: final func (other: This) -> Bool {
        this == other
    }

    /** return the character at position #*index* (starting at 0) */
    charAt: func (index: SizeT) -> Char {
        get(index)
    }

    /** return a copy of *this*. */
    clone: func -> This {
        clone(size)
    }

    clone: func ~withMinimum (minimumLength : SizeT) -> This {
        copy := this new( minimumLength > size ? minimumLength : size )
        copy setLength(size)
        memcpy( copy data, data, size)
        return copy
    }

    substring: func ~tillEnd (start: SizeT) {
        substring(start, size)
    }

    /** *this* will be reduced to the characters in the range ``start..end``.  */
    substring: func (start: SizeT, end: SizeT) {
        if (end != size) setLength(end)
        if (start > 0) shiftRight(start)
    }

    /** return a This that contains *this*, repeated *count* times. */
    times: func (count: SizeT) {
        if (_literal?()) _makeWritable()
        origSize := size
        setLength (origSize * count)
        for(i in 1..count) { // we start at 1, since the 0 entry is already there
            memcpy(data + (i * origSize), this data, origSize)
        }
    }

    append: func ~buf(other: This) {
        //cprintf("[%p:%s]trying to append a buffer %p %s\n", size, data, other size, other data)
        append~pointer(other data, other size)
    }

    append: func ~str(other: String) {
        append~buf(other _buffer)
    }


    /** appends *other* to *this* */
    append: func ~pointer (other: Char*, otherLength: SizeT) {
        //cprintf("buffer append called on %p:%s with %p bytes: %s\n", size, data, otherLength, other)
        if(otherLength > 1 && (other + otherLength)@ != '\0') Exception new ("something wrong here!") throw()
        if(otherLength > 1 && (other + 1)@ == '\0') Exception new ("something wrong here!") throw()
        if (_literal?()) _makeWritable()
        origlen := size
        setLength(size + otherLength)
        memcpy(data + origlen, other, otherLength )
    }

    /** appends a char to either *this* or a clone*/
    append: func ~char (other: Char)  {
        append(other&, 1)
    }

    /** prepends *other* to *this*. */
    prepend: func ~buf (other: This) {
        prepend(other data, other size)
    }

    /** return a new string containg *other* followed by *this*. */
    prepend: func ~pointer (other: Char*, otherLength: SizeT) {
        if (_literal?()) _makeWritable()
        if (_rshift() < otherLength) {
            newthis := This new (size + otherLength)
            memcpy (newthis data, other, otherLength)
            memcpy (newthis data + otherLength, data, size)
            setBuffer(newthis)
        } else {
            // seems we have enough room on the left
            shiftLeft(otherLength)
            memcpy( data , other, otherLength )
        }
    }

    /** replace *this* or a clone with  *other* followed by *this*. */
    prepend: func ~char (other: Char) {
        prepend( other&, 1)
    }

    /** compare *length* characters of *this* with *other*, starting at *start*.
        Return true if the two strings are equal, return false if they are not. */
    compare: func (other: This, start, length: SizeT) -> Bool {
        if (size < (start + length)) return false
        for(i: SizeT in 0..length) {
            if( (data + start + i)@ != (other data + i)@) {
                return false
            }
        }
        return true
    }

    /** compare *this* with *other*, starting at *start*. The count of compared
        characters is determined by *other*'s length. */
    compare: func ~implicitLength (other: This, start: SizeT) -> Bool {
        compare(other, start, other length())
    }

    /** compare *this* with *other*, starting at 0. Compare ``other length()`` characters. */
    compare: func ~whole (other: This) -> Bool {
        compare(other, 0, other length())
    }

    /** return true if the string is empty or ``null``. */
    empty?: func -> Bool { (size == 0 || this data == null) }

    /** return true if the first characters of *this* are equal to *s*. */
    startsWith?: func (s: This) -> Bool {
        len := s length()
        if (size < len) return false
        compare(s, 0, len)
    }

    /** return true if the first character of *this* is equal to *c*. */
    startsWith?: func ~char(c: Char) -> Bool {
        return (size > 0) && (data@ == c)
    }

    /** return true if the last characters of *this* are equal to *s*. */
    endsWith?: func (s: This) -> Bool {
        len := s size
        if (size < len) return false
        compare(s, size - len, len )
    }

    /** return true if the last character of *this* is equal to *c*. */
    endsWith?: func ~char(c: Char) -> Bool {
        size > 0 && (data + size)@ == c
    }


    /**
        calls find with searchCaseSenitive set to true by default
        returns -1 if nothing is found, otherwise the position  */
    find : func (what: This, offset: SSizeT) -> SSizeT {
        find(what data, what size, offset, true)
    }

    find : func ~char (what: Char, offset: SSizeT) -> SSizeT {
        find (what&, 1, offset, true)
    }

    find : func ~charWithCase (what: Char, offset: SSizeT, searchCaseSensitive: Bool) -> SSizeT {
        find (what&, 1, offset, searchCaseSensitive)
    }

    /**
        returns -1 when not found, otherwise the position of the first occurence of "what"
        use offset 0 for a new search, then increase it by the last found position +1
        look at implementation of findAll() for an example
    */
    find : func ~withCase (what: This, offset: SSizeT, searchCaseSensitive : Bool) -> SSizeT {
        find~pointer(what data, what size, offset, searchCaseSensitive)
    }

    find : func ~pointer (what: Char*, whatSize: SizeT, offset: SSizeT, searchCaseSensitive : Bool) -> SSizeT {
        if (offset >= size || offset < 0 || what == null || whatSize == 0) return -1

        maxpos : SSizeT = size - whatSize // need a signed type here
        if ((maxpos) < 0) return -1

        found : Bool
        sstart := offset


        while (sstart <= maxpos) {
            found = true
            for (j in 0..(whatSize)) {
                if (searchCaseSensitive) {
                    if ( (data + sstart + j)@ != (what + j)@ ) {
                        found = false
                        break
                    }
                } else {
                    if ( (data + sstart + j)@ toUpper() != (what + j)@ toUpper() ) {
                        found = false
                        break
                    }
                }
            }
            if (found) return sstart
            sstart += 1
        }
        return -1
    }

    /** returns a list of positions where buffer has been found, or an empty list if not */
    findAll: func ( what : This) -> ArrayList <SizeT> {
        findAll( what, true)
    }

    /** returns a list of positions where buffer has been found, or an empty list if not  */
    findAll: func ~withCase ( what : This, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        findAll(what data, what size, searchCaseSensitive)
    }

    findAll: func ~pointer ( what : Char*, whatSize: SizeT, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        if (what == null || whatSize == 0) return ArrayList <SizeT> new(0)
        //cprintf("find called on %p:%s with %p:%s\n", size, data, whatSize, what)
        if(whatSize > 1 && (what + whatSize)@ != '\0') Exception new ("something wrong here!") throw()
        if(whatSize > 1 && (what + 1)@ == '\0') Exception new ("something wrong here!") throw()
        result := ArrayList <SizeT> new (size / whatSize)
        offset : SSizeT = (whatSize ) * -1
        while (((offset = find(what, whatSize, offset + whatSize , searchCaseSensitive)) != -1)) result add (offset)
        //for (elem in result) cprintf("%d\n", elem)
        return result
    }

    /** replaces all occurences of *what* with *whit */
    replaceAll: func ~buf (what, whit : This) {
        replaceAll(what, whit, true);
    }

    replaceAll: func ~bufWithCase (what, whit : This, searchCaseSensitive: Bool) {
        //cprintf("replaceAll called on %p:%s with %p:%s\n", size, data, what size, what)
        //if (_literal?()) _makeWritable()
        if (what == null || what size == 0 || whit == null) return
        l := findAll( what, searchCaseSensitive )
        if (l == null || l size() == 0) return
        newlen: SizeT = size + (whit size * l size()) - (what size * l size())
        result := This new~withSize( newlen, false )

        sstart: SizeT = 0 //source (this) start pos
        rstart: SizeT = 0 //result start pos

        for (item in l) {
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
        memcpy(result data + rstart, data  + sstart, sdist + 1)    // +1 to copy the trailing zero as well
        setBuffer( result )
    }

    /** replace all occurences of *oldie* with *kiddo* in place/ in a clone, if immutable is set */
    replaceAll: func ~char(oldie, kiddo: Char) {
        if (_literal?()) _makeWritable()
        for(i in 0..size) {
            if((data + i)@ == oldie) (data + i)@ = kiddo
        }
    }

    split: func~withChar(c: Char, maxSplits: SSizeT) -> ArrayList <This> {
        split(c&, 1, maxSplits)
    }

    /** split s and return *all* elements, including empties */
    split: func~withStringWithoutMaxSplits(s: This) -> ArrayList <This> {
        split ( s data, s size, -1)
    }

    split: func~withCharWithoutMaxSplits(c: Char) -> ArrayList <This> {
        split(c&, 1, -1)
    }

    split: func~withBufWithEmpties( s: This, empties: Bool) -> ArrayList <This> {
        split (s data, s size, empties ? -1 : 0 )
    }

    split: func~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList <This> {
        split( c& , 1,  empties ? -1 : 0 )
    }

    /** splits a string into an ArrayList, maxSplits denotes max elements of returned list
        if it is > 0, it will be splitted maxSplits -1 times, and in the last element the rest of the string will be held.
        if maxSplits is negative, it will return all elements, if 0 it will return all non-empty elements.
        pretty much the same as in java.*/
    // FIXME untested!
    split: func ~buf (delimiter: This, maxSplits: SSizeT) -> ArrayList <This> {
        split(delimiter data, delimiter size, maxSplits)
    }

    split: func ~pointer (delimiter: Char*, delimiterLength:SizeT, maxSplits: SSizeT) -> ArrayList <This> {
        //cprintf("self[%p:%s] split called with %p:%s", size, data, delimiterLength, delimiter)
        l := findAll(delimiter, delimiterLength, true)
        maxItems := ((maxSplits <= 0) || (maxSplits >= l size())) ? l size() : maxSplits
        result := ArrayList <This> new( maxItems )
        sstart: SizeT = 0 //source (this) start pos
        for (item in l) {
            if ( ( maxSplits > 0 ) && ( result size() == maxItems - 1 ) ) break
            sdist := item - sstart // bytes to copy
            if (maxSplits != 0 || sdist > 0) {
                b := This new ((data + sstart) as CString, sdist)
                result add ( b )
            }
            sstart += sdist + delimiterLength
        }
        sdist := size - sstart // bytes to copy
        b := This new ((data + sstart) as CString, sdist)
        result add ( b )
        //cprintf("split debug out:\n")
        //for (elem in result) cprintf("%p:%s\n", elem size, elem data)
        return result
    }

    /** characters lowercased (if possible). */
    toLower: func {
        if (_literal?()) _makeWritable()
        for(i in 0..size) {
            (data + i)@ = (data  + i)@ toLower()
        }
    }

    /** characters uppercased (if possible). */
    toUpper: func {
        if (_literal?()) _makeWritable()
        for(i in 0..size) {
            (data + i)@ = (data  + i)@ toUpper()
        }
    }
    /* i hate circular references. */
    toString: func -> String { String new(this) }

    /** return the index of *c*, starting at 0. If *this* does not contain *c*, return -1. */
    indexOf: func ~charZero (c: Char) -> SSizeT {
        indexOf(c, 0)
    }

    /** return the index of *c*, but only check characters ``start..length``.
        However, the return value is the index of the *c* relative to the
        string's beginning. If *this* does not contain *c*, return -1. */
    indexOf: func ~char (c: Char, start: SizeT) -> SSizeT {
        for(i in start..size) {
            if((data + i)@ == c) return i
        }
        return -1
    }

    /** return the index of *s*, starting at 0. If *this* does not contain *s*,
        return -1. */
    indexOf: func ~bufZero (s: This) -> SSizeT {
        indexOf~buf(s, 0)
    }

    /** return the index of *s*, but only check characters ``start..length``.
        However, the return value is relative to the *this*' first character.
        If *this* does not contain *c*, return -1. */
    indexOf: func ~buf (s: This, start: Int) -> SSizeT {
        return find(s, start, false)
    }


    /** return *true* if *this* contains the character *c* */
    contains?: func ~char (c: Char) -> Bool { indexOf(c) != -1 }

    /** return *true* if *this* contains the string *s* */
    contains?: func ~buf (s: This) -> Bool { indexOf(s) != -1 }

    /** all characters contained by *s* stripped at both ends. */
    trimMulti: func ~pointer (s: Char*, sLength: SizeT) {
        if (_literal?()) _makeWritable()
        if(size == 0 || sLength == 0) return
        start := 0
        while (start < size && (data + start)@ containedIn? (s, sLength) ) start += 1
        end := size
        while (end > 0 && (data + end -1)@ containedIn? (s, sLength) ) end -= 1
        if(start >= end) start = end
        substring(start, end)
    }

    trimMulti: func ~buf(s : This) {
        trim(s data, s size)
    }

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
        trim( WHITE_SPACE, WHITE_SPACE length())
    }

    /** space characters (ASCII 32) stripped from the left side. */
    trimLeft: func ~space { trimLeft(' ') }

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

    /** return (a copy of) *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~pointer (s: Char*, sLength: SizeT) {
    //c :Char= s@
    //if (sLength == 1) cprintf("trimRight: %02X\n", c)
    //else cprintf("trimRight: %p:%s\n", sLength, s)
        if(sLength > 1 && (s + sLength)@ != '\0') raise("something wrong here!")
        if(sLength > 1 && (s + 1)@ == '\0') raise("something wrong here!")

        end := size
        while( end > 0 &&  (data + (end - 1))@ containedIn?(s, sLength)) {
            //cprintf("%c contained in %s!\n", (data + (end - 1))@, s)
            end -= 1
        }
        if (end != size) setLength(end);
    }

    /** reverses *this*. "ABBA" -> "ABBA" .no. joke. "ABC" -> "CBA" */
    reverse: func {
        if (_literal?()) _makeWritable()
        result := this
        bytesLeft := size
        i: SizeT = 0
        while (bytesLeft > 1) {
            c := (result data + i)@
            (result data + i)@ = (result data + ((size-1)-i))@
            (result data + ((size-1)-i))@ = c
            bytesLeft -= 2
            i += 1
        }
    }

    /** return the number of *what*'s occurences in *this*. */
    count: func (what: Char) -> SizeT {
        result : SizeT = 0
        for(i in 0..size) {
            if((data + i)@ == what)
                result += 1
        }
        result
    }

    /** return the number of *what*'s non-overlapping occurences in *this*. */
    count: func ~buf (what: This) -> SizeT {
        l := findAll(what)
        return l size()
    }

    /** return the first character of *this*. If *this* is empty, 0 is returned. */
    first: func -> Char {
        return data@
    }

    /** return the index of the last character of *this*. If *this* is empty,
        -1 is returned. */
    lastIndex: func -> SSizeT {
        return length() - 1
    }

    /** return the last character of *this*. */
    last: func -> Char {
        return (data + lastIndex())@
    }

    /** return the index of the last occurence of *c* in *this*.
        If *this* does not contain *c*, return -1. */
    lastIndexOf: func (c: Char) -> SSizeT {
        // could probably use reverse foreach here
        i : SSizeT = size - 1
        while(i >= 0) {
            if((data +i)@ == c) return i
            i -= 1
        }
        return -1
    }

    /** print *this* to stdout without a following newline. Flush stdout. */
    print: func { cprintf("%s", data) }

    /** print *this* followed by a newline. */
    //TODO printf("%s\n", data should work as well, but thats not the case...
    println: func { print(); "\n" print() }

    /*
        TODO make these faster by not simply calling the C api
         now that we have the length stored we have an advantage
    */

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
        reads a whole file into buffer, binary mode
    */
    fromFile: func (fileName: String) -> Bool {
        STEP_SIZE : const SizeT = 4096
        file := FStream open(fileName, "rb")
        if (!file || file error()) return false
        len := file size()
        setLength(len)
        offset :SizeT= 0
        while (len / STEP_SIZE > 0) {
            retv := file read((data + offset) as Pointer, STEP_SIZE)
            if (retv != STEP_SIZE || file error()) {
                file close()
                return false
            }
            len -= retv
            offset += retv
        }
        if (len) file read((data + offset) as Pointer, len)
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
            retv := file write ((data + offset) as String, STEP_SIZE)
            if (retv != STEP_SIZE || file error()) {
                file close()
                return false
            }
            togo -= retv
            offset  += retv
        }
        if (togo) file write((data + offset) as String, togo)
        return (file error() == 0) && (file close()==0 )
    }

    // at last: our varargs "friends"

    /** returns a formated string using *this* as template. */
    // TODO this just doesnt make sense
    // TODO mutable / immutable after a decision
    format: final func ~ str (...) {
        list:VaList
        fmt := this

        va_start(list, this)
        length := vsnprintf(null, 0, (fmt data), list)
        va_end(list)

        copy := This new(length)

        va_start(list, this )
        vsnprintf((copy data), length + 1, (fmt data), list)
        va_end(list)
        setBuffer( copy )
    }

    printf: final func ~str (...) {
        assert(false) // invalid method call
        list: VaList

        va_start(list, this )
        vprintf((this data), list)
        va_end(list)
    }

    vprintf: final func ~str (list: VaList) {
        assert(false) // invalid method call
        vprintf(this data, list)
    }

    printfln: final func ~str ( ...) {
        assert(false) // invalid method call

        list: VaList

        va_start(list, this )
        vprintf(this data, list)
        va_end(list)
        '\n' print()
    }

    scanf: final func ~str (format: This, ...) -> Int {
        assert(false) // invalid method call

        list: VaList
        va_start(list, (format))
        retval := vsscanf(this data, format data, list)
        va_end(list)

        return retval
    }

    // safest & slowest way to access a Char
    get: func ~chr (offset: SizeT) -> Char {
        if(offset >= size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }
        return (data + offset)@
    }

    get: func ~strWithLengthOffset (str: Char*, offset: SizeT, length: SizeT) -> SizeT {
        if(offset >= size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }

        copySize: SizeT
        if((offset + length) > size) {
            copySize = size - offset
        }
        else {
            copySize = length
        }

        memcpy(str, (data as Char*) + offset, copySize)
        copySize
    }

}

/**
 * iterators
 */

BufferIterator: class <T> extends BackIterator<T> {

    i := 0
    str: Buffer

    init: func ~withStr (=str) {}

    hasNext?: func -> Bool {
        i < str size
    }

    next: func -> T {
        c := (str data +i)@
        i += 1
        return c
    }

    hasPrev?: func -> Bool {
        i > 0
    }

    prev: func -> T {
        i -= 1
        return (str data + i)@
    }

    remove: func -> Bool { false } // this could be implemented!

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

    write: func (chars: Char*, length: SizeT) -> SizeT {
        buffer append(chars, length)
        return length
    }

    /*     check out the Writer writef method for a simple varargs usage,
        this version here is mostly for internal usage (it is called by writef)
        */
    vwritef: func(fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt, list2)
        va_end (list2)

        origSize := buffer size
        buffer setLength( origSize + length)
        vsnprintf(buffer data + origSize, length + 1, fmt, list)
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

    read: func(chars: Char*, offset: Int, count: Int) -> SizeT {
        copySize := buffer get(chars + offset, marker, count)
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

operator == (str1: Buffer, str2: Buffer) -> Bool {
    if (str1 == null && str2 != null) return false
    if (str2 == null && str1 != null) return false
    if (str1 == null && str2 == null) return true
    return ( str1 size == str2 size) &&  ( memcmp ( str1 data , str2 data , str1 size ) == 0 )
}

operator != (str1: Buffer, str2: Buffer) -> Bool {
    return !(str1 == str2)
}

operator [] (string: Buffer, index: SizeT) -> Char {
    assert(string != null && index < string size)
    string charAt(index)
}

operator []= (string: Buffer, index: SizeT, value: Char) {
    assert(string != null && index < string size)
    (string data + index)@ = value
}

operator [] (string: Buffer, range: Range) -> Buffer {
    assert(string != null)
    b:= string clone()
    b substring(range min, range max)
    b
}

operator * (string: Buffer, count: Int) -> Buffer {
    assert(string != null)
    b := string clone( string size * count )
    b times(count)
    b
}

operator + (left, right: Buffer) -> Buffer {
    assert((left != null) && (right != null))
    b := left clone ( left size + right size )
    b append(right)
    b
}

operator + (left: Buffer, right: Char) -> Buffer {
    assert(left != null)
    b := left clone(left size + 1)
    b append(right)
    b
}

operator + (left: Char, right: Buffer) -> Buffer {
    assert(right != null)
    b := Buffer new(1 + right size)
    b append(left)
    b append(right)
    b
}



/*  Test routines
    TODO use kinda builtin assert which doesnt crash when one test fails
    once unittest facility is builtin
*/
Buffer_unittest: class {

    testFile: static func {
        // this one is a bit nasty :P
        // TODO make it work on windows as well
        TEST_FILE_IN : const String = "/usr/bin/env"
        TEST_FILE_OUT : const String = "/tmp/buftest"

        b := Buffer new(0)
        if (!b fromFile(TEST_FILE_IN) || b size == 0) "read failed: b size=%d" format(b size) println()
        if (!(b toFile(TEST_FILE_OUT)))     ("write failed") println()
        if (! ((c := Buffer new(0) fromFile(TEST_FILE_IN) )     == b ) ) ("comparison failed") println()
    }

    testFind: static func {
        b := String new ("123451234512345")
        what := String new ("1")
        p := b find(what, 0)
        p = b find(what, p+1)
        p = b find(what, p+1)

        l := b findAll( String new ("1"))
        if ( l size() != ( 3 as SizeT)) ( "find failed 1") println()
        else {
            if ( l get(0) != 0) ( "find failed 2") println()
            if ( l get(1) != 5) ( "find failed 3") println()
            if ( l get(2) != 10) ( "find failed 4") println()
        }
    }

    testOperators: static func {

        if (String new ("1") == String new(0) ) ("op equals failed 3") println()
        if (String new ("123") == String new("1234") ) ("op equals failed 4") println()
        if (String new ("1234") != String new("1234") ) ("op equals failed 5") println()
        if (String new ("1234") == String new("4444") ) ("op equals failed 6") println()
    }

    testReplace: static func {
        if ( String new ("1234512345") replaceAll( "1", "2") != String new ("2234522345") )  ("replace failed 1," + String new ("1234512345") replaceAll( "1", "2")) println()
        if ( String new ("1234512345") replaceAll( "12333333333333333333", "2") != String new ("1234512345") )  ("replace failed 2") println()
        if ( String new ("1234512345") replaceAll( "23", "11") != String new ("1114511145") )  ("replace failed 3") println()
        if ( String new ("112") replaceAll( "1", "XXX") != String new ("XXXXXX2") )  ("replace failed 4, " + String new ("112") replaceAll( "1", "XXX")) println()
        if ( String new ("112") replaceAll( "1", "") != String new ("2") )  ("replace failed 5") println()
        if ( String new ("111") replaceAll( "1", "") != String new ("") )  ("replace failed 6") println()
        if ( String new ("") replaceAll( "1", "") != String new ("") )  ("replace failed 7") println()
        if ( String new ("") replaceAll( "", "1") != String new ("") )  ("replace failed 8") println()
        if ( String new ("111") replaceAll( "", "") != String new ("111") )  ("replace failed 9") println()
    }

    testSplit: static func {
        if (("X XXX X") split (" ") size() != 3) Exception new ("split failed 1") throw()
        if (("X XXX X") split (" ") get(0) != String new("X"))  ("split failed 2") println()
        if (("X XXX X") split (" ") get(1) != String new ("XXX"))  ("split failed 3") println()
        if (("X XXX X") split (" ") get(2) != String new ("X"))  ("split failed 4") println()
        /* actually that's hows it supposed to be, java has an additional argument to solve this: split(";" -1) or so
        if (Buffer new ("X XXX X") split ("X") size() != 2) println("split failed 5")
        b := Buffer new ("X XXX X") split ("X")
        for (item in b) {
            if (item) (item toString() + "_") println()
            else "null" println()
        }
        */
    }

    testTrailingZero: static func {
        b := Buffer new (0)
        b setLength(4)
        b size = 0
        memcpy (b data as Char*, "1111", 4)
        b append(Buffer new("222"))
        if (b data[3] != '\0') ("trZero failed 1") println()
    }

    unittest: static func {
        testOperators()
        testFile()
        testFind()
        testReplace()
        testSplit()
        testTrailingZero()
    }

}
