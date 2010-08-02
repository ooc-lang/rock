import text/Buffer /* for String replace ~string */
import structs/ArrayList

include stdlib

__LINE__: extern Int
__FILE__: extern String
__FUNCTION__: extern String

puts: extern func(Char*) -> Int

strcmp: extern func (Char*, Char*) -> Int
strncmp: extern func (Char*, Char*, SizeT) -> Int
strstr: extern func (Char*, Char*)
strlen:  extern func (Char*) -> SizeT

strtol:  extern func (Char*, Pointer, Int) -> Long
strtoll: extern func (Char*, Pointer, Int) -> LLong
strtoul: extern func (Char*, Pointer, Int) -> ULong
strtof:  extern func (Char*, Pointer)      -> Float
strtod:  extern func (Char*, Pointer)      -> Double
strtold: extern func (Char*, Pointer)      -> LDouble

/**
 * character and pointer types
 */
Char: cover from char {

    /** check for an alphanumeric character */
    alphaNumeric?: func -> Bool {
        alpha?() || digit?()
    }

    /** check for an alphabetic character */
    alpha?: func -> Bool {
        lower?() || upper?()
    }

    /** check for a lowercase alphabetic character */
    lower?: func -> Bool {
        this >= 'a' && this <= 'z'
    }

    /** check for an uppercase alphabetic character */
    upper?: func -> Bool {
        this >= 'A' && this <= 'Z'
    }

    /** check for a decimal digit (0 through 9) */
    digit?: func -> Bool {
        this >= '0' && this <= '9'
    }

    /** check for a hexadecimal digit (0 1 2 3 4 5 6 7 8 9 a b c d e f A B C D E F) */
    hexDigit?: func -> Bool {
        digit?() ||
        (this >= 'A' && this <= 'F') ||
        (this >= 'a' && this <= 'f')
    }

    /** check for a control character */
    control?: func -> Bool {
        (this >= 0 && this <= 31) || this == 127
    }

    /** check for any printable character except space */
    graph?: func -> Bool {
        printable?() && this != ' '
    }

    /** check for any printable character including space */
    printable?: func -> Bool {
        this >= 32 && this <= 126
    }

    /** check for any printable character which is not a space or an alphanumeric character */
    punctuation?: func -> Bool {
        printable?() && !alphaNumeric?() && this != ' '
    }

    /** check for white-space characters: space, form-feed ('\\f'), newline ('\\n'),
        carriage return ('\\r'), horizontal tab ('\\t'), and vertical tab ('\\v') */
    whitespace?: func -> Bool {
        this == ' '  ||
        this == '\f' ||
        this == '\n' ||
        this == '\r' ||
        this == '\t' ||
        this == '\v'
    }

    /** check for a blank character; that is, a space or a tab */
    blank?: func -> Bool {
        this == ' ' || this == '\t'
    }

    /** convert to an integer. This only works for digits, otherwise -1 is returned */
    toInt: func -> Int {
        if (digit?()) {
            return (this - '0')
        }
        return -1
    }

    /** return the lowered character */
    toLower: extern(tolower) func -> This

    /** return the capitalized character */
    toUpper: extern(toupper) func -> This

    /** return a one-character string containing this character. */
    toString: func -> String {
        String new(this)
    }

    /** write this character to stdout without a following newline. */
    print: func {
        "%c" printf(this)
    }

    /** write this character to stdout, followed by a newline */
    println: func {
        "%c\n" printf(this)
    }

    containedIn?: func(s : String) -> Bool {
        containedIn?(s data, s length())
    }

    containedIn?: func ~charWithLength (s : Char*, sLength: SizeT) -> Bool {
        for (i in 0..sLength) {
            if ((s + i)@ == this) return true
        }
        return false
    }


}

SChar: cover from signed char extends Char
UChar: cover from unsigned char extends Char
WChar: cover from wchar_t

operator as (value: Char) -> String {
    value toString()
}

String: class {

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

    /* used to overwrite the data of *this* with that of another one */
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
    init: func ~withLength (length: SizeT) -> This {
        setLength(length)
        this
    }

    /** Create a new string of the length 1 containing only the character *c* */
    init: func ~withChar (c: Char) -> This {
        this setLength(1)
        data@ = c
        this
    }

    /** create a new String from a zero-terminated C String */
    init: func ~withCStr(s : Char*) -> This {
        init (s, strlen(s))
    }

    /** create a new String from a zero-terminated C String with known length */
    init: func ~withCStrAndLength(s : Char*, length: SizeT) -> This {
        setLength(length)
        memcpy(data, s, length + 1)
        this
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

    /** *this* will be reduced to the characters in the range ``start..length``.  */
    substring: func ~immutableChoiceTillEnd (start: SizeT, immutable: Bool) -> This{
        substring(start, size, immutable)
    }

    /** *this* will be reduced to the characters in the range ``start..end``.  */
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
    replaceAll: func ~buf (what, whit : This) {
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

    split: func ~buf (delimiter: This) -> ArrayList <This> {
        l := findAll(delimiter, true)
        result := ArrayList <This> new(l size())
        sstart: SizeT = 0 //source (this) start pos
        for (item in l) {
            sdist := item - sstart // bytes to copy
            b := This new (data+ sstart, sdist)
            result add ( b )
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


    iterator: func -> StringIterator<Char> {
        StringIterator<Char> new(this)
    }

    forward: func -> StringIterator<Char> {
        iterator()
    }

    backward: func -> BackIterator<Char> {
        backIterator() reversed()
    }

    backIterator: func -> StringIterator<Char> {
        iter := StringIterator<Char> new(this)
        iter i = length()
        return iter
    }

    // at last: our varargs "friends"

    /** returns a formated string using *this* as template. */
    // TODO this just doesnt make sense
    // TODO mutable / immutable after a decision
    format: final func ~ str (...) -> String {
        list:VaList
        fmt := this

        va_start(list, fmt)
        length := vsnprintf(null, 0, (fmt data), list)
        va_end(list)

        copy := String new(length)

        va_start(list, fmt )
        vsnprintf((copy data), length + 1, (fmt data), list)
        va_end(list)
        return copy
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

StringIterator: class <T> extends BackIterator<T> {

    i := 0
    str: String

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

operator == (str1: String, str2: String) -> Bool {
    return str1 equals?(str2)
}

operator != (str1: String, str2: String) -> Bool {
    return !str1 equals?(str2)
}

operator [] (string: String, index: SizeT) -> Char {
    string charAt(index)
}

operator []= (string: String, index: SizeT, value: Char) {
    if(index < 0 || index > string length()) {
        Exception new(String, "Writing to a String out of bounds index = %d, length = %d!" format(index, string length())) throw()
    }
    (string data + index)@ = value
}

operator [] (string: String, range: Range) -> String {
    string substring(range min, range max)
}

operator * (str: String, count: Int) -> String {
    return str times(count)
}

operator + (left, right: String) -> String {
    return left append(right)
}

operator + (left: LLong, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: LLong) -> String {
    left + right toString()
}

operator + (left: Int, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Int) -> String {
    left + right toString()
}

operator + (left: Bool, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Bool) -> String {
    left + right toString()
}

operator + (left: Double, right: String) -> String {
    left toString() + right
}

operator + (left: String, right: Double) -> String {
    left + right toString()
}

operator + (left: String, right: Char) -> String {
    left append(right)
}

operator + (left: Char, right: String) -> String {
    right prepend(left)
}

