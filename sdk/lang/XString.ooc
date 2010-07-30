import structs/ArrayList


xString: cover {

    /*  stores current size of string */
    size: SizeT

    /*  stores count of currently alloced mem */
    capacity: SizeT

    /*  stores amount of bytes the data pointer was increased since alloc
        use only in combination with shiftLeft function
        this is mainly used if a trimleft is done, so that we don't have to do length mallocs */
    rshift : SizeT

    /* stores the data, this must be implicitly passed to functions working with Char* */
    data : Char*

    new: static func~zero -> This {
        return this
    }

    /** Create a new string exactly *length* characters long (without the nullbyte).
        The contents of the string are undefined.
        the new strings length is also set to length. */
    new: static func~withLength (length: SizeT) -> This {
        setLength(length)
        return this
    }

    /** Create a new string of the length 1 containing only the character *c* */
    new: static func~withChar (c: Char) -> This {
        result := This new~withLength(1)
        result[0] = c
        result
    }

    /** create a new String from a zero-terminated C String */
    new: static func~withCStr(s : Char*) -> This {
        len := strlen(s)
        result := This new~withLength(len)
        memcpy(result data, s, len)
        result
    }

    /** sets capacity to a sane amount and (re)allocs the needed memory,size aka length stays untouched */
    setCapacity: func(length: SizeT) {
        /* we do a trick: if length is 0, we'll let it point to capacity
            this way we have a valid zero length, zero terminated string, without using malloc */
        if (data == null && length == 0 && capacity == 0 && size == 0) {
            data as Pointer = capacity& as Pointer
            return
        }
        min := length + 1
        if(min >= capacity) {
            // if length was 0 before, reset the data pointer so our trick above works
            if (size == 0 && capacity == 0 && data == capacity&) data = null
            newCapa := min * 1.2 + 10
            // align at 8 byte boundary
            newCapa += newCapa % 8
            // subtract rshift from data, so we can point to a mem location known by the GC
            if(data) data -= rshift
            else rshift = 0 // this line should never be executed, but it will still prevent a crash
            tmp := gc_realloc(data, newCapa)
            if(!tmp) {
                Exception new(This, "Couldn't allocate enough memory for Buffer to grow to capacity "+newCapa) throw()
            }
            capacity = newCapa
            data = tmp + rshift
        }
        // just to be sure to be always zero terminated
        (data as Char* + length)@ = '\0'
    }

    /** sets capacity and size flag, and a zero termination */
    setLength: func(length: SizeT) {
        setCapacity(length)
        size = length
        (data as Char* + size)@ = '\0'
    }


    /** compare *length* characters of *this* with *other*, starting at *start*.
        Return true if the two strings are equal, return false if they are not. */
    compare: func (other: This, start, length: SizeT) -> Bool {
        if (size < (start + length)) return false
        for(i: SizeT in 0..length) {
            if(this[start + i] != other[i]) {
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

    /** return the string's length, excluding the null byte. */
    length: func -> SizeT {
        return size
    }

    /** return true if *other* and *this* are equal. */
    equals?: func(other: This) -> Bool {
        if (!this && !other) return true
        if ((!this && other) || (!other && this)) return false
        return ( (size == other size) &&  ( memcmp ( data , other data , size ) == 0 ) )
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
    toLLong: func -> LLong                         { strtol(this data, null, 10)   }
    toLLong: func ~withBase (base: LLong) -> LLong { strtol(this data, null, base) }

    /** convert the string's contents to Unsigned Long. */
    toULong: func -> ULong                         { strtoul(this data, null, 10)   }
    toULong: func ~withBase (base: ULong) -> ULong { strtoul(this data, null, base) }

    /** convert the string's contents to Float. */
    toFloat: func -> Float                         { strtof(this data, null)   }

    /** convert the string's contents to Double. */
    toDouble: func -> Double                       { strtod(this data, null)   }

    /** convert the string's contents to Long Double. */
    toLDouble: func -> LDouble                     { strtold(this data, null)   }

    /** return true if the string is empty or ``null``. */
    empty?: func -> Bool { (size == 0 || this data == null) }

    /** return true if the first characters of *this* are equal to *s*. */
    startsWith?: func(s: This) -> Bool {
        len := s length()
        if (size < len) return false
        compare(s, 0, len)
    }

    /** return true if the first character of *this* is equal to *c*. */
    startsWith?: func~withChar(c: Char) -> Bool {
        return (size > 0) && (this[0] == c)
    }

    /** return true if the last characters of *this* are equal to *s*. */
    endsWith?: func(s: This) -> Bool {
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


    /** return the index of *c*, starting at 0. If *this* does not contain *c*, return -1. */
    indexOf: func ~charZero (c: Char) -> SSizeT {
        indexOf(c, 0)
    }

    /** return the index of *c*, but only check characters ``start..length``.
        However, the return value is the index of the *c* relative to the
        string's beginning. If *this* does not contain *c*, return -1. */
    indexOf: func ~char (c: Char, start: SizeT) -> SSizeT {
        length := length()
        for(i: Int in start..length) {
            if(this[i] == c) {
                return i
            }
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

    /** whitespace characters (space, CR, LF, tab) stripped at both ends. */
    trim: func ~whitespace { trim(" \r\n\t") }

    /** returns a "whitespace characters (space, CR, LF, tab) stripped at both ends" clone */
    trim: func ~immutableWithWhitespace -> This{ return trim (" \r\n\t") }

    /* trims *this* in place */
    trim: func(c: Char) ~char -> This {
        trim (c, false)
    }

    /** *c* characters stripped at both ends. */
    trim: func~ charImmutableChoice (c: Char, immutable: Bool) -> This {
        s : This* = immutable ? clone()& : this&
        if(s@ size == 0) return

        start :SizeT = 0
        while (s@ [start] == c) start += 1

        end :SizeT = s@ size
        if( start < end) {
            while(s@ [end - 1] == c) end -= 1
        } else start = end

        s@ = s@ substring(start, end, immutable)
        return s@
    }

    trim: func ~string (s: This ) -> This {
        trim(s, false)
    }

    /** all characters contained by *s* stripped at both ends. */
    // TODO this function does not do what one expects, suggest renaming
    trim: func ~stringImmutableChoice (s: This, immutable: Bool) -> This{
        p : This* = immutable ? this clone()& : this&

        if(p@ size == 0 || s size == 0) return p@

        start := 0
        while (start < p@ size && p@ [start] containedIn? (s) ) start += 1

        end := p@ size
        while (end > 0 && p@ [end -1] containedIn? (s) ) end -= 1

        if(start >= end) start = end
        p@ = p@ substring(start, end, immutable)
        p@
    }

    /* creates a clone on which the trimleft function is executed */
    trimLeft: func ~immutableWithSpace -> This {
        copy := clone()
        copy trimLeft ~space
        return copy
    }

    /** space characters (ASCII 32) stripped from the left side. */
    trimLeft: func ~space { trimLeft(' ') }

    /* creates a clone on which the trimleft function is executed */
    trimLeft: func ~immutableWithChar (c: Char) -> This {
        copy := clone
        copy trimLeft( c )
        return copy
    }

    /*  shifts data pointer to the right count bytes if possible
        if count is bigger as possible shifts right maximum possible
        size and capacity is decreased accordingly  */

    // remark: can be called with negative value (done by leftShift)
    shiftRight( count: SSizeT ) {
        if (count == 0) return
        c := count
           if (c > size) c = size
           else if (c < 0 && c abs() > rshift) c = rshift *-1
        data += c
           size -= c
           capacity -= c
           rshift += c
    }

    /* shifts back count bytes, only possible if shifted right before */
    shiftLeft( count : SSizeT) {
        shiftRight ( count * -1) // it can be so easy
    }

    /** *c* character stripped from the left side. */
    trimLeft: func ~char (c: Char) -> This {
        trimLeft(c, false)
    }

    /** *c* character stripped from the left side. */
    trimLeft: func ~charImmutableChoice (c: Char, immutable: Bool) -> This {
        p: This* = immutable ? this clone()& : this&
        while(p@ size as SSizeT > 0 && p@ data@ == c ) p@ shiftLeft(1)
        p@
    }

    /** all characters contained by *s* stripped from the left side. */
    trimLeft: func ~string (s: This) -> This {
        trimLeft(s, false)
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~stringImmutableChoice (s: This, immutable: Bool) -> This {
        p : This* = immutable ? this clone()& : this&
        if (p@ length() == 0 || s length() == 0) return p@
        start : SizeT = 0
        while (start < p@ length() && p@ [start] containedIn?(s) ) {
            start += 1
        }
           p@ shiftLeft( start )
           return p@
    }

    /** space characters (ASCII 32) stripped from the right side. */
    trimRight: func ~space -> This { trimRight(' ') }

    /** *c* characters stripped from the right side. */
    trimRight: func ~charImmutableChoice (c: Char) -> This {
        trimRight(c, false)
    }

    /** *c* characters stripped from the right side. */
    trimRight: func ~charImmutableChoice (c: Char, immutable: Bool) -> This {
        s : This* = immutable ? this clone()& : this&
        while( s@ size > 0 &&  @s [size - 1] == c) s@ setLength(s@ size -1);
        s@
    }

    /** strip *this* with all characters contained by *s* from the right side. */
    trimRight: func ~string (s: This) -> This{
        trimRight (s, false)
    }

    /** return (a copy of) *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~stringImmutableChoice (s: This, immutable: Bool) -> This{
        t : This* = immutable ? this clone()& : this&
        while( t@ size > 0 &&  t@ [size - 1] containedIn?(s)) t@ setLength(size -1);
        t@
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
    lastIndexOf: func(c: Char) -> SSizeT {
        // could probably use reverse foreach here
        i : SSizeT = length() - 1
        while(i >= 0) {
            if(this[i] == c) return i
            i -= 1
        }
        return -1
    }


    substring: func ~tillEnd (start: SizeT) -> This {
        substring(start, length(), false)
    }

    substring: func (start, end: SizeT) -> This {
           substring(start, end, false)
    }

    /** *this* will be reduced to the characters in the range ``start..length``.  */
    substring: func ~immutableChoiceTillEnd (start: SizeT, immutable: Bool) -> This{
        substring(start, length(), immutable)
    }

    /** *this* will be reduced to the characters in the range ``start..end``.  */
    substring: func ~immutableChoice (start, end: SizeT, immutable: Bool) -> This{
        s: This* = immutable ? this clone()& : this&
        s@ setLength(end)
        s@ shiftRight(start)
        return s@
    }

    /** reverses string in place */
    reverse: func -> This {
        reverse(false)
    }

    /** reverses string in place */
    reverse: func~immutable -> This {
        reverse(true)
    }

    /** reverses *this*. "ABBA" -> "ABBA" .no. joke. "ABC" -> "CBA"
        if immutable is set, returns a new String. otherwise the old will be
        manipulated and returned */
    reverse: func~immutableChoice(immutable : Bool) -> This {
        if (!size) return
        result := This new(size)
        for (i: SizeT in 0..size) {
            result[i] = this[(size-1)-i]
        }
        if (immutable) return result
        this = result
        this
    }

    /** print *this* to stdout without a following newline. Flush stdout. */
    print: func {
        "%s" printf(this); stdout flush()
    }

    /** print *this* followed by a newline. */
    println: func {
        "%s\n" printf(this)
    }

    /** return a string that contains *this*, repeated *count* times. */
    times: func (count: SizeT) -> This {
        times (count, false)
    }

    /** return a string that contains *this*, repeated *count* times. */
    times: func ~immutableChoice (count: SizeT, immutable: Bool) -> This {
        length := length()
        result := This new ( length * count )
        for(i in 0..count) {
            memcpy(result data as Char* + (i * length), this data, length)
        }
        if (immutable) return result
        this = result
        this
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

    append: func ~str(other: This) -> This {
        append(other, false)
    }

    /** appends *other* to *this*, if not immutable, otherwise to a clone */
    append: func~immutableChoice(other: This, immutable: Bool) -> This{
        s : This* = immutable ? this clone ( size + other size )& : this&
           origlen = size
        otherlen := other length()
        s@ setlength( origlen + otherlen )
        memcpy(s@ data + origlen, other data, otherlen )
        return s@
    }

    append: func ~char (other: Char ) -> This {
        append(other, false)
    }

    /** appends a char to either *this* or a clone*/
    append: func ~charImmutableChoice (other: Char, immutable: Bool) -> This {
        s : This* = immutable ? this clone(size + 1)& : this&
        s@ setlength ( size + 1 )
        s@ [size-1] = other
    }

    /** return the number of *what*'s occurences in *this*. */
    count: func ~char (what: Char) -> SizeT {
        count: SizeT = 0
        for(i: SizeT in 0..size)) {
            if(this[i] == what)
                count += 1
        }
        return count
    }

    /** return the number of *what*'s non-overlapping occurences in *this*. */
    count: func ~string (what: This) -> SizeT {
        l := findAll(what)
        return l size()
    }

    /** replaces all occurences of *what* with *whit */
    replaceAll: func ~buf (what, whit : This) {
        replaceAll(what, whit, true, false);
    }

    replaceAll: func ~bufWithCase (what, whit : This, searchCaseSensitive: Bool, immutable: Bool) -> This{
        if (what == null || what size == 0 || whit == null) return

        l := findAll( what, searchCaseSensitive )

        if (l == null || l size() == 0) return
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
        memcpy(result data as Char* + rstart, data as Char* + sstart, sdist + 1)    // +1 to copy the trailing zero as well
        if (immutable) return result
        this = result
        this
    }

    /** replace all occurences of *oldie* with *kiddo* in place */
    replaceAll: func ~char(oldie, kiddo: Char) -> This{
        replaceAll(oldie, kiddo, false)
    }

    /** replace all occurences of *oldie* with *kiddo* in place/ in a clone, if immutable is set */
    replaceAll: func ~charImmutableChoice (oldie, kiddo: Char, immutable: Bool) -> This{
        s: This* = immutable ? clone()& : this&
        for(i in 0..size) {
            if(s@ [i] == oldie) s@ [i] = kiddo
        }
        s@
    }

    /** prepends *other* to *this*. */
    prepend: func ~str (other: This) -> This {
        prepend(other, false)
    }

    /** return a new string containg *other* followed by *this*. */
    prepend: func ~immutableChoice (other: This, immutable: Bool) -> This {
        if (rshift < other size || immutable) {
            newthis := This new (length() + other length())
            memcpy (newthis data, other data, other length())
            memcpy (newthis data + other length, this data, this length())
            if (immutable) return newthis
            this = newthis
            return this
        } else {
            // seems we have enough room on the left, and we are allowed to morph
            shiftLeft(other size)
            memcpy( data , other data, other size )
            return this
        }
    }

    /** replace *this* with  *other* followed by *this*. */
    prepend: func ~char (other: Char) -> This{
        prepend(other, false)
    }

    /** replace *this* or a clone with  *other* followed by *this*. */
    prepend: func ~charImmutableChoice (other: Char, immutable: Bool) -> This{
        if (rshift < 1 || immutable) {
            newthis := This new (length() + 1 ))
            newthis data[0] = other
            memcpy (newthis data + 1, this data, this length())
            if (immutable) return newthis
            this = newthis
            return this
        } else {
            // seems we have enough room on the left, and we are allowed to morph
            shiftLeft(1)
            data@ = other
            return this
        }
    }

    toLower: func -> This {
        toLower(false)
    }

    /** characters lowercased (if possible). */
    toLower: func ~immutableChoice (immutable : Bool) -> This {
        s: This* = immutable ? this clone()& : this&
        length := s@ length()
        for(i in 0..length) {
            s@ [i] = s@ [i] toLower()
        }
        s@
    }

    toUpper: func -> This {
        toUpper(false)
    }

    /** characters uppercased (if possible). */
    toUpper: func ~immutableChoice(immutable: Bool) -> This {
        s: This* = immutable ? this clone()& : this&
        length := s@ length()
        for(i in 0..length) {
            s@ [i] = s@ [i] toUpper()
        }
        s@
    }

    /** return the character at position #*index* (starting at 0) */
    charAt: func(index: SizeT) -> Char {
        if(index as SSizeT < 0 || index > length()) {
            Exception new(This, "Accessing a String out of bounds index = %d, length = %d!" format(index, length())) throw()
        }
        this[index]
    }

    split: func ~buf (delimiter: This) -> ArrayList <This> {
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

    /** returns a formated string using *this* as template. */
    // TODO this just doesnt make sense
    format: func (...) -> This {
        fmt := this clone()
        immutable: Bool = true

        list:VaList

        va_start(list, fmt data)
        length := vsnprintf(null, 0, fmt data, list)
        va_end(list)

        This* s = immutable ? This new()& : this&
        s@ setLength(length)

        va_start(list, fmt)
        vsnprintf(s@ data, length + 1, fmt data, list)
        va_end(list)
        @s
    }

    printf: func (...) {
        list: VaList

        va_start(list, this)
        vprintf(this, list)
        va_end(list)
    }

    vprintf: func (list: VaList) {
        vprintf(this, list)
    }

    printfln: func (...) {
        list: VaList

        va_start(list, this)
        vprintf(this, list)
        va_end(list)
        '\n' print()
    }

    scanf: func (format: This, ...) -> Int {
        list: VaList
        va_start(list, format)
        retval := vsscanf(this, format, list)
        va_end(list)

        return retval
    }

    iterator: func -> xStringIterator<Char> {
        StringIterator<Char> new(this)
    }

    forward: func -> xStringIterator<Char> {
        iterator()
    }

    backward: func -> xBackIterator<Char> {
        backIterator() reversed()
    }

    backIterator: func -> xStringIterator<Char> {
        iter := xStringIterator<Char> new(this)
        iter i = length()
        return iter
    }
}

/**
 * iterators
 */

xStringIterator: class <T> extends BackIterator<T> {

    i := 0
    str: xString

    init: func ~withStr (=str) {}

    hasNext?: func -> Bool {
        i < str length()
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

operator == (str1: xString, str2: xString) -> Bool {
    return str1 equals?(str2)
}

operator != (str1: xString, str2: xString) -> Bool {
    return !str1 equals?(str2)
}

operator [] (string: xString, index: SizeT) -> Char {
    string charAt(index)
}

operator []= (string: xString, index: SizeT, value: Char) {
    if(index < 0 || index > string length()) {
        Exception new(xString, "Writing to a String out of bounds index = %d, length = %d!" format(index, string length())) throw()
    }
    (string as Char*)[index] = value
}

operator [] (string: xString, range: Range) -> xString {
    string substring(range min, range max)
}

operator * (str: xString, count: Int) -> xString {
    return str times(count)
}

operator + (left, right: xString) -> xString {
    return left append(right)
}

operator + (left: LLong, right: xString) -> xString {
    left toXString() + right
}

operator + (left: xString, right: LLong) -> xString {
    left + right toXString()
}

operator + (left: Int, right: xString) -> xString {
    left toXString() + right
}

operator + (left: xString, right: Int) -> xString {
    left + right toXString()
}

operator + (left: Bool, right: xString) -> xString {
    left toXString() + right
}

operator + (left: xString, right: Bool) -> xString {
    left + right toXString()
}

operator + (left: Double, right: xString) -> xString {
    left toXString() + right
}

operator + (left: xString, right: Double) -> xString {
    left + right toXString()
}

operator + (left: xString, right: Char) -> xString {
    left append(right)
}

operator + (left: Char, right: xString) -> xString {
    right prepend(left)
}

