import io/[Writer, Reader]
import structs/ArrayList
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
        we need eat so the GC doesn't accidentally free the mem, when we shift the data pointer */
    /*   shifting of data ptr is used only in combination with shiftRight function
        this is mainly used if a trimleft is done, so that we don't have to do lengthy mallocs */
    mallocAddr : Pointer

    /* pointer to the string data's start byte, this must be implicitly passed to functions working with Char* */
    data : Char*

    debug: func { printf ("size: %x. capa: %x. rshift: %x. data: %x. data@: %s\n", size, capacity, rshift(), data, data) }

    rshift: func -> SizeT { return mallocAddr != null ? (data as SizeT - mallocAddr as SizeT) as SizeT: 0 }

    /* used to overwrite the data/attributes of *this* with that of another String */
    setString: func( newOne : This ) {
        data = newOne data
        mallocAddr = newOne mallocAddr
        size = newOne size
        capacity = newOne capacity
    }

    init: func ~zero -> This { init(0) }

    /** Create a new string exactly *length* characters long (without the nullbyte).
        The contents of the string are undefined.
        the new strings length is also set to length. */
    init: func ~withLength (length: SizeT) {
        setLength(length)
    }

    init: func ~str (str: String) {
        setString(str clone())
    }

    /** Create a new string of the length 1 containing only the character *c* */
    init: func ~withChar (c: Char) {
        setLength(1)
        data@ = c
    }

    /** create a new String from a zero-terminated C String */
    init: func ~withCStr(s : Char*) {
        init (s, strlen(s))
    }

    /** create a new String from a zero-terminated C String with known length */
    // ATTENTION the mangled name of this function is hardcoded in CGenerator.ooc
    // so you'd rather not change it
    init: func ~withCStrAndLength(s : Char*, length: SizeT) {
        setLength(length)
        memcpy(data, s, length + 1)
    }

    /** return the string's length, excluding the null byte. */
    length: func -> SizeT {
        return size
    }


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
        min += rshift()
        if(min >= capacity) {
            // if length was 0 before, reset the data pointer so our trick above works
            if (size == 0 && capacity == 0 && mallocAddr == 0) data = null
            capacity = (min * 120) / 100 + 10 // let's stay integer, mkay ?
            // align at 8 byte boundary
            al := 8 - (capacity % 8)
            if (al < 8) capacity += al

            rs := rshift()
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
        setCapacity(length)
        size = length
        (data as Char* + size)@ = '\0'
    }

    /*  shifts data pointer to the right count bytes if possible
        if count is bigger as possible shifts right maximum possible
        size and capacity is decreased accordingly  */

    // remark: can be called with negative value (done by leftShift)
    shiftRight: func ( count: SSizeT ) {
        //printf("sR : %d\n", count)
        //debug()
        if (count == 0 || size == 0) return
        c := count
        rshift := rshift()
        if (c > size) c = size
        else if (c < 0 && c abs() > rshift) c = rshift *-1
        data += c
        size -= c
        //debug()
    }

    /* shifts back count bytes, only possible if shifted right before */
    shiftLeft: func ( count : SSizeT) {
        shiftRight ( count * -1) // it can be so easy
    }

    /** return true if *other* and *this* are equal (in terms of being null / having same size and content). */
    equals?: func (other: This) -> Bool {
        if ((this == null) && (other == null)) return true
        if ( ( (this == null) && (other  != null) ) || ( (other == null) && (this != null) ) ) return false
        return ( (size == other size) &&  ( memcmp ( data , other data , size ) == 0 ) )
    }

    /** return the character at position #*index* (starting at 0) */
    charAt: func (index: SizeT) -> Char {
        if(index as SSizeT < 0 || index > length()) {
            Exception new(This, "Accessing a String out of bounds index = %d, length = %d!" format(index, length())) throw()
        }
        (data + index)@
    }

    /** return a copy of *this*. */
    clone: func -> This {
        clone(size)
    }

    clone: func ~withMinimum (minimumLength : SizeT) -> This {
        copy := this new( minimumLength > size ? minimumLength : size )
        memcpy( copy data, data, size + 1)
        return copy
    }

    substring: func ~tillEnd (start: SizeT) -> This {
        substring(start, size, false)
    }

    substring: func (start, end: SizeT) -> This {
           substring(start, end, false)
    }

    /** *this* or a clone will be reduced to the characters in the range ``start..length``.  */
    substring: func ~immutableChoiceTillEnd (start: SizeT, immutable: Bool) -> This{
        substring(start, size, immutable)
    }

    /** *this* or a clone will be reduced to the characters in the range ``start..end``.  */
    substring: func ~immutableChoice (start: SizeT, end: SizeT, immutable: Bool) -> This{
        s:=getPtr(immutable)
        s setLength(end)
        s shiftRight(start)
        s
    }

    /** return a string that contains *this*, repeated *count* times. */
    times: func (count: SizeT) -> This {
        times (count, false)
    }

    /** return a string that contains *this*, repeated *count* times. */
    times: func ~immutableChoice (count: SizeT, immutable: Bool) -> This {
        origSize := size
        result := getPtr(origSize * count, immutable)
        for(i in 1..count) { // we start at 1, since the 0 entry is already there
            memcpy(result data + (i * origSize), this data, origSize)
        }
        return result
    }

    append: func ~str(other: This) -> This {
        append(other data, other size, false)
    }

    /** appends *other* to *this*, if not immutable, otherwise to a clone */
    append: func ~withPointerAndLength (other: Char*, otherLength: SizeT) -> This {
        append(other, otherLength, false)
    }

    /** appends *other* to *this*, if not immutable, otherwise to a clone */
    append: func ~immutableChoice (other: Char*, otherLength: SizeT, immutable: Bool) -> This {
        origlen := size
        s := getPtr(size + otherLength, immutable)
        memcpy(s data + origlen, other, otherLength )
        s
    }

    append: func ~char (other: Char ) -> This {
        append(other, false)
    }

    /** appends a char to either *this* or a clone*/
    append: func ~charImmutableChoice (other: Char, immutable: Bool) -> This {
        append(other&, 1, immutable)
    }

    /** prepends *other* to *this*. */
    prepend: func ~str (other: This) -> This {
        prepend(other data, other size, false)
    }

    /** return a new string containg *other* followed by *this*. */
    prepend: func ~immutableChoice (other: Char*, otherLength: SizeT, immutable: Bool) -> This {
        if (rshift() < otherLength || immutable) {
            newthis := This new (size + otherLength)
            memcpy (newthis data, other, otherLength)
            memcpy (newthis data + otherLength, data, size)
            if (immutable) return newthis
            setString(newthis)
            this
        } else {
            // seems we have enough room on the left, and we are allowed to morph
            shiftLeft(otherLength)
            memcpy( data , other, otherLength )
            this
        }
    }

    /** replace *this* with  *other* followed by *this*. */
    prepend: func ~char (other: Char) -> This{
        prepend(other&, 1, false)
    }

    /** replace *this* or a clone with  *other* followed by *this*. */
    prepend: func ~charImmutableChoice (other: Char, immutable: Bool) -> This{
        prepend( other&, 1, immutable)
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
    startsWith?: func ~withChar(c: Char) -> Bool {
        return (size > 0) && (data@ == c)
    }

    /** return true if the last characters of *this* are equal to *s*. */
    endsWith?: func (s: This) -> Bool {
        len := s length()
        if (size < len) return false
        compare(s, size - len, len )
    }

    /**
        calls find with searchCaseSenitive set to true by default
        -1 is returned if nothing is found
        otherwise the position
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
            if (found)     return sstart
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
        if (what == null || what size == 0) return ArrayList <SizeT> new(0)
        result := ArrayList <SizeT> new (size / what size)
        offset : SSizeT = (what size ) * -1
        while (((offset = find(what, offset + what size , searchCaseSensitive)) != -1)) result add (offset)
        return result
    }

    /* legacy function, do use replaceAll instead */
    replace: func ~stringObsolete (oldie, kiddo: This) -> This {
        replaceAll(oldie, kiddo, true, false )
    }

    /* legacy function, do use replaceAll instead */
    replace: func ~charObsolete (oldie, kiddo: Char) -> This {
        replaceAll(oldie, kiddo)
    }

    /** replaces all occurences of *what* with *whit */
    replaceAll: func ~buf (what, whit : This) -> This {
        replaceAll(what, whit, true, false);
    }

    replaceAll: func ~bufWithCase (what, whit : This, searchCaseSensitive: Bool, immutable: Bool) -> This{
        if (what == null || what size == 0 || whit == null) return immutable ? clone() : this
        l := findAll( what, searchCaseSensitive )
        if (l == null || l size() == 0) return immutable ? clone() : this
        newlen: SizeT = size + (whit size * l size()) - (what size * l size())
        result := This new( newlen + 1)
        result size = newlen

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
        memcpy(result data as Char* + rstart, data as Char* + sstart, sdist + 1)    // +1 to copy the trailing zero as well
        if (immutable) return result
        setString( result )
        this
    }

    /** replace all occurences of *oldie* with *kiddo* in place */
    replaceAll: func ~char(oldie, kiddo: Char) -> This{
        replaceAll(oldie, kiddo, false)
    }

    /** replace all occurences of *oldie* with *kiddo* in place/ in a clone, if immutable is set */
    replaceAll: func ~charImmutableChoice (oldie, kiddo: Char, immutable: Bool) -> This{
        s:= getPtr(immutable)
        for(i in 0..s size) {
            if((s data + i)@ == oldie) (s data + i)@ = kiddo
        }
        s
    }


    /* uses str as a set of delimiters of size 1 and splits accordingly
        as for maxSplits, the same rules as those from split apply */
    // FIXME untested !
    splitMulti: func(str: This, maxSplits: SSizeT) -> ArrayList <This> {
        start := 0
        maxItems := (maxSplits > 0) ? maxSplits : INT_MAX;
        result := ArrayList<This> new (16)
        for (i in 0..size) {
            if ( (data + i )@ containedIn? (str) ) {
                if ((maxItems -1) == result size()) {
                    result add ( substring (start, size , true) )
                    break
                }
                if ((maxSplits != 0) || (start < i)) result add ( substring (start, i , true) )
                start = i + 1
            }
        }
        result
    }

    split: func~withChar(c: Char, maxSplits: SSizeT) -> ArrayList <This> {
        split(This new(c), maxSplits)
    }

    /** split s and return *all* elements, including empties */
    split: func~withStringWithoutMaxSplits(s: This) -> ArrayList <This> {
        split ( s, -1)
    }

    split: func~withCharWithoutMaxSplits(c: Char) -> ArrayList <This> {
        split( This new(c))
    }

    split: func~withStringWithEmpties( s: This, empties: Bool) -> ArrayList <This> {
        split (s, empties ? -1 : 0 )
    }

    split: func~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList <This> {
        split( This new (c) , empties )
    }

    /** splits a string into an ArrayList, maxSplits denotes max elements of returned list
        if it is > 0, it will be splitted maxSplits -1 times, and in the last element the rest of the string will be held.
        if maxSplits is negative, it will return all elements, if 0 it will return all non-empty elements.
        pretty much the same as in java.*/
    // FIXME untested!
    split: func ~buf (delimiter: This, maxSplits: SSizeT) -> ArrayList <This> {
        l := findAll(delimiter, true)
        maxItems := ((maxSplits <= 0) || (maxSplits >= l size())) ? l size() : maxSplits
        result := ArrayList <This> new( maxItems )
        sstart: SizeT = 0 //source (this) start pos
        for (item in l) {
            if ( ( maxSplits > 0 ) && ( result size() == maxItems - 1 ) ) break
            sdist := item - sstart // bytes to copy
            if (maxSplits != 0 || sdist > 0) {
                b := This new (data+ sstart, sdist)
                result add ( b )
            }
            sstart += sdist + delimiter size
        }
        sdist := size - sstart // bytes to copy
        b := This new (data + sstart, sdist)
        result add ( b )
        return result
    }

    /* small internal helper function to get pointer to destination string, based upon immutable
        if immutable is true, it will return a clone, otherwise *this* to work on */
    getPtr: func ~immutableChoice (immutable: Bool) -> This {
        return immutable ? clone() : this
    }

    /* small internal helper function to get pointer to destination string, based upon immutable
        if immutable is true, it will return a clone, otherwise *this* to work on
        assures a minimum size of *minimumSize* in both cases */
    getPtr: func ~immutableChoiceWithMinimum (minimumSize: SizeT, immutable: Bool) -> This {
        if (immutable) return clone(minimumSize)
        else {
            setLength(minimumSize)
            return this
        }
    }

    toLower: func -> This {
        toLower(false)
    }

    /** characters lowercased (if possible). */
    toLower: func ~immutableChoice (immutable : Bool) -> This {
        tmp:= getPtr(immutable)
        for(i in 0..tmp size) {
            (tmp data + i)@ = (tmp data  + i)@ toLower()
        }
        tmp
    }

    toUpper: func -> This {
        toUpper(false)
    }

    /** characters uppercased (if possible). */
    toUpper: func ~immutableChoice(immutable: Bool) -> This {
        tmp := getPtr(immutable)
        for(i in 0..tmp size) {
            (tmp data + i)@ = (tmp data  + i)@ toUpper()
        }
        tmp
    }
    /* only for descendants, on which toString() is called, i.e. Buffer */
    toString: func -> This { return this }

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
    indexOf: func ~stringZero (s: This) -> Int {
        indexOf~string(s, 0)
    }

    /** return the index of *s*, but only check characters ``start..length``.
        However, the return value is relative to the *this*' first character.
        If *this* does not contain *c*, return -1. */
    indexOf: func ~string (s: This, start: Int) -> Int {
        return find(s, start, false)
    }


    /** return *true* if *this* contains the character *c* */
    contains?: func ~char (c: Char) -> Bool { indexOf(c) != -1 }

    /** return *true* if *this* contains the string *s* */
    contains?: func ~string (s: This) -> Bool { indexOf(s) != -1 }

    /** all characters contained by *s* stripped at both ends. */
    // TODO this function does not do what one expects, suggest renaming
    trim: func ~pointerImmutableChoice (s: Char*, sLength: SizeT, immutable: Bool) -> This{
        tmp := getPtr(immutable)

        if(tmp size == 0 || sLength == 0) return tmp
        start := 0
        while (start < tmp size && tmp[start] containedIn? (s, sLength) ) start += 1
        end := tmp size
        while (end > 0 && tmp[end -1] containedIn? (s, sLength) ) end -= 1
        if(start >= end) start = end
        tmp substring(start, end, immutable)
    }

    trim: func ~stringImmutableChoice(s : This, immutable: Bool) -> This {
        trim( s data, s size, immutable)
    }

    /** *c* characters stripped at both ends. */
    trim: func ~charImmutableChoice (c: Char, immutable: Bool) -> This {
        trim(c&, 1, immutable)
    }

    trim: func ~string (s: This ) -> This {
        trim(s, false)
    }

    /** whitespace characters (space, CR, LF, tab) stripped at both ends. */
    trim: func ~whitespace -> This {
        whiteSpace : Char* = " \r\n\t"
        trim( whiteSpace, 4, false)
    }

    /* trims *this* in place */
    trim: func ~char (c: Char) -> This {
        trim (c&, 1, false)
    }

    /** space characters (ASCII 32) stripped from the left side. */
    trimLeft: func ~space -> This { trimLeft(' ') }

    /** *c* character stripped from the left side. */
    trimLeft: func ~char (c: Char) -> This {
        trimLeft(c, false)
    }

    /** *c* character stripped from the left side. */
    trimLeft: func ~charImmutableChoice (c: Char, immutable: Bool) -> This {
        trimLeft(c&, 1, immutable)
    }

    /** all characters contained by *s* stripped from the left side. */
    trimLeft: func ~string (s: This) -> This {
        trimLeft(s, false)
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~stringImmutableChoice (s: This, immutable: Bool) -> This {
        trimLeft(s data, s size, immutable)
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~pointerImmutableChoice (s: Char*, sLength: SizeT, immutable: Bool) -> This {
        p:= getPtr(immutable)

        if (p size == 0 || sLength == 0) return p

        start : SizeT = 0
        while (start < p length() && p [start] containedIn?(s, sLength) ) start += 1
        p shiftRight( start )
        return p
    }

    /** space characters (ASCII 32) stripped from the right side. */
    trimRight: func ~space -> This { trimRight(' ') }

    /** *c* characters stripped from the right side. */
    trimRight: func ~char (c: Char) -> This {
        trimRight(c, false)
    }

    /** *c* characters stripped from the right side. */
    trimRight: func ~charImmutableChoice (c: Char, immutable: Bool) -> This {
        trimRight(c&, 1, immutable)
    }

    /** strip *this* with all characters contained by *s* from the right side. */
    trimRight: func ~string (s: This) -> This{
        trimRight (s, false)
    }

    /** return (a copy of) *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~stringImmutableChoice (s: This, immutable: Bool) -> This{
        trimRight(s data, s size, immutable)
    }

    /** return (a copy of) *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~pointerImmutableChoice (s: Char*, sLength: SizeT, immutable: Bool) -> This{
        p := getPtr(immutable)
        while( p size > 0 &&  (p data + (size - 1))@ containedIn?(s, sLength)) p setLength(size -1);
        p
    }

    /** reverses string in place */
    reverse: func -> This {
        reverse(false)
    }

    /** reverses *this*. "ABBA" -> "ABBA" .no. joke. "ABC" -> "CBA"
        if immutable is set, returns a new String. otherwise the old will be
        manipulated and returned */
    reverse: func ~immutableChoice(immutable : Bool) -> This {
        result := getPtr(immutable)
        bytesLeft := size
        i: SizeT = 0
        while (bytesLeft > 1) {
            c := (result data + i)@
            (result data + i)@ = (result data + ((size-1)-i))@
            (result data + ((size-1)-i))@ = c
            bytesLeft -= 2
            i += 1
        }
        return result
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
    count: func ~string (what: This) -> SizeT {
        l := findAll(what)
        return l size()
    }

    /** return the first character of *this*. If *this* is empty, 0 is returned. */
    first: func -> Char {
        return this[0]
    }

    /** return the index of the last character of *this*. If *this* is empty,
        -1 is returned. */
    lastIndex: func -> SSizeT {
        return length() - 1
    }

    /** return the last character of *this*. */
    last: func -> Char {
        return this[lastIndex()]
    }

    /** return the index of the last occurence of *c* in *this*.
        If *this* does not contain *c*, return -1. */
    lastIndexOf: func (c: Char) -> SSizeT {
        // could probably use reverse foreach here
        i : SSizeT = size - 1
        while(i >= 0) {
            if(this[i] == c) return i
            i -= 1
        }
        return -1
    }

    /** print *this* to stdout without a following newline. Flush stdout. */
    print: func {
        This new("%s") printf( this data)
        //This new ("%s") printf(this); stdout flush()
    }

    /** print *this* followed by a newline. */
    println: func {
        This new("%s\n") printf( this data )
        //This new ("%s\n") printf(this)
    }

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

    // at last: our varargs "friends"

    /** returns a formated string using *this* as template. */
    // TODO this just doesnt make sense
    // TODO mutable / immutable after a decision
    format: final func ~ str (...) -> This {
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
        list: VaList

        va_start(list, this )
        vprintf((this data), list)
        va_end(list)
    }

    vprintf: final func ~str (list: VaList) {
        vprintf(this data, list)
    }

    printfln: final func ~str ( ...) {
        list: VaList

        va_start(list, this )
        vprintf(this data, list)
        va_end(list)
        '\n' print()
    }

    scanf: final func ~str (format: This, ...) -> Int {
        list: VaList
        va_start(list, (format))
        retval := vsscanf(this data, format data, list)
        va_end(list)

        return retval
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
        c := str[i]
        i += 1
        return c
    }

    hasPrev?: func -> Bool {
        i > 0
    }

    prev: func -> T {
        i -= 1
        return str[i]
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

    write: func (chars: String, length: SizeT) -> SizeT {
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
    return ( (a size == b size) &&     ( memcmp ( a data as Char*, b data as Char*, a size ) == 0 ) )
}

operator != (a, b: Buffer) -> Bool {
    if (a == b) return false
    else        return true
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
        if (!b fromFile(TEST_FILE_IN) || b size == 0) println("read failed: b size=%d" format (b size))
        if (!(b toFile(TEST_FILE_OUT)))     println("write failed")
        if (! ((c := Buffer new(0) fromFile(TEST_FILE_IN) )     == b ) ) println( "comparison failed")
    }

    testFind: static func {
        b := Buffer new ("123451234512345")
        what := Buffer new ("1")
        p := b find(what, 0)
        p = b find(what, p+1)
        p = b find(what, p+1)

        l := b findAll( Buffer new ("1"))
        if ( l size() != ( 3 as SizeT)) println( "find failed 1")
        else {
            if ( l get(0) != 0) println( "find failed 2")
            if ( l get(1) != 5) println( "find failed 3")
            if ( l get(2) != 10) println( "find failed 4")
        }
    }

    testOperators: static func {
        if (null as Buffer != null as Buffer) println("op equals failed 1")
        if (null as Buffer == Buffer new(0) ) println("op equals failed 2 ")
        if (Buffer new ("1") == Buffer new(0) ) println("op equals failed 3")
        if (Buffer new ("123") == Buffer new("1234") ) println("op equals failed 4")
        if (Buffer new ("1234") != Buffer new("1234") ) println("op equals failed 5")
        if (Buffer new ("1234") == Buffer new("4444") ) println("op equals failed 6")
    }

    testReplace: static func {
        if ( Buffer new ("1234512345") replaceAll( "1", "2") != Buffer new ("2234522345") ) println ("replace failed 1," + Buffer new ("1234512345") replaceAll( "1", "2") toString())
        if ( Buffer new ("1234512345") replaceAll( "12333333333333333333", "2") != Buffer new ("1234512345") ) println ("replace failed 2")
        if ( Buffer new ("1234512345") replaceAll( "23", "11") != Buffer new ("1114511145") ) println ("replace failed 3")
        if ( Buffer new ("112") replaceAll( "1", "XXX") != Buffer new ("XXXXXX2") ) println ("replace failed 4, " + Buffer new ("112") replaceAll( "1", "XXX") toString() )
        if ( Buffer new ("112") replaceAll( "1", "") != Buffer new ("2") ) println ("replace failed 5")
        if ( Buffer new ("111") replaceAll( "1", "") != Buffer new ("") ) println ("replace failed 6")
        if ( Buffer new ("") replaceAll( "1", "") != Buffer new ("") ) println ("replace failed 7")
        if ( Buffer new ("") replaceAll( "", "1") != Buffer new ("") ) println ("replace failed 8")
        if ( Buffer new ("111") replaceAll( "", "") != Buffer new ("111") ) println ("replace failed 9")
    }

    testSplit: static func {
        if (Buffer new ("X XXX X") split (" ") size() != 3) println ("split failed 1")
        if (Buffer new ("X XXX X") split (" ") get(0) != Buffer new("X")) println ("split failed 2")
        if (Buffer new ("X XXX X") split (" ") get(1) != Buffer new ("XXX")) println ("split failed 3")
        if (Buffer new ("X XXX X") split (" ") get(2) != Buffer new ("X")) println ("split failed 4")
        /* actually that's hows it supposed to be, java has an additional argument to solve this: split(";" -1) or so
        if (Buffer new ("X XXX X") split ("X") size() != 2) println ("split failed 5")
        b := Buffer new ("X XXX X") split ("X")
        for (item in b) {
            if (item) (item toString() + "_") println()
            else "null" println()
        }
        */
    }

    testTrailingZero: static func {
        b := Buffer new (0)
        b checkLength(4)
        memcpy (b data as Char*, "1111", 4)
        b append("222")
        if (b data[3] != '\0') println("trZero failed 1")
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
