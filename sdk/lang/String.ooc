import text/Buffer /* for String replace ~string */

/*  The String class is immutable by default, this means every writing operation
    is done on a clone, which is then returned
    */

String: class {

    // accessing this member directly can break immutability, so you should avoid it.
    _buffer: Buffer

    size: SizeT { get { _buffer size } ; set { } }

    init: func { _buffer = Buffer new() }

    init: func ~withBuffer(b: Buffer) { _buffer = b }

    init: func ~withChar(c: Char) { _buffer = Buffer new~withChar(c)) }

    init: func ~withLength (length: SizeT) { _buffer = Buffer new~withLength(length) }

    init: func ~withString (s: String) { _buffer = Buffer new~withBuffer( s _buffer ) }

    init: func ~withCStr (s : CString) { _buffer = Buffer new~withCStr(s) }

    init: func ~withCStrAndLength(s : CString, length: SizeT) { _buffer = Buffer new~withCStrAndLength(s, length) }

    /** return the string's length, excluding the null byte. */
    length: func -> SizeT { _buffer size }

    /** return true if *other* and *this* are equal (in terms of being null / having same size and content). */
    equals?: func (other: This) -> Bool { _buffer equals? (other _buffer) }

    /** return the character at position #*index* (starting at 0) */
    charAt: func (index: SizeT) -> Char { _buffer charAt(index) }

    /** return a copy of *this*. */
    clone: func -> This {
        This new( _buffer clone() )
    }

    substring: func ~tillEnd (start: SizeT) -> This { substring(start, _buffer size) }

    substring: func (start: SizeT, end: SizeT) -> This{
        result :=clone()
        result _buffer substring(start, end)
        result
    }

    /** return a This that contains *this*, repeated *count* times. */
    times: func (count: SizeT) -> This{
        result := clone()
        result _buffer times(count)
        result
    }

    append: func ~str(other: This) {
        result := clone()
        result _buffer append~str(other _buffer)
        result
    }

    /** appends a char to either *this* or a clone*/
    append: func ~char (other: Char)  {
        result := clone()
        result _buffer append~char(other)
        result
    }

    /** prepends *other* to *this*. */
    prepend: func ~str (other: This) {
        result := clone()
        result _buffer prepend~str(other _buffer)
        result
    }

    /** replace *this* with  *other* followed by *this*. */
    prepend: func ~char (other: Char) {
        result := clone()
        result _buffer prepend~char(other)
        result
    }

    compare: func (other: This, start, length: SizeT) -> Bool {
        _buffer compare(other _buffer, start, length)
    }

    /** compare *this* with *other*, starting at *start*. The count of compared
        characters is determined by *other*'s length. */
    compare: func ~implicitLength (other: This, start: SizeT) -> Bool {
        _buffer compare(other _buffer, start)
    }

    /** compare *this* with *other*, starting at 0. Compare ``other length()`` characters. */
    compare: func ~whole (other: This) -> Bool {
        _buffer compare(other _buffer)
    }

    /** return true if the string is empty or null. */
    empty?: func -> Bool { _buffer empty? }

    startsWith?: func (s: This) -> Bool { _buffer startsWith? (s _buffer) }

    /** return true if the first character of *this* is equal to *c*. */
    startsWith?: func ~char(c: Char) -> Bool { _buffer startsWith?~char(c) }

    /** return true if the last characters of *this* are equal to *s*. */
    endsWith?: func (s: This) -> Bool { _buffer endsWith? (s) }

    /** return true if the last character of *this* is equal to *c*. */
    endsWith?: func ~char(c: Char) -> Bool { _buffer endsWith?~char (s) }

    find : func (what: This, offset: SSizeT) -> SSizeT { _buffer find( what _buffer, offset }

    find : func ~withCase (what: This, offset: SSizeT, searchCaseSensitive : Bool) -> SSizeT {
        _buffer find~withCase( what _buffer, offset, searchCaseSensitive
    }

    /** returns a list of positions where buffer has been found, or an empty list if not */
    findAll: func ( what : This) -> ArrayList <SizeT> { _buffer findAll( what _buffer ) }

    /** returns a list of positions where buffer has been found, or an empty list if not  */
    findAll: func ~withCase ( what : This, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        _buffer findAll~withCase( what _buffer, searchCaseSensitive )
    }

    /** replaces all occurences of *what* with *whit */
    replaceAll: func ~str (what, whit : This) -> This {
        result := clone()
        _buffer replaceAll~buf (what _buffer, whit _buffer)
        result
    }

    replaceAll: func ~strWithCase (what, whit : This, searchCaseSensitive: Bool) -> This {
        result := clone()
        _buffer replaceAll~buf (what _buffer, whit _buffer, searchCaseSensitive)
        result
    }

    /** replace all occurences of *oldie* with *kiddo* in place/ in a clone, if immutable is set */
    replaceAll: func ~char(oldie, kiddo: Char) -> This {
        result := clone()
        _buffer replaceAll~char(oldie, kiddo)
        result
    }

    _bufArrayListToStrArrayList ( x : ArrayList<Buffer> ) -> ArrayList<This> {
        result := ArrayList<This> new( x size() )
        for (i in x) result add (This new~withBuffer( i ) )
        result
    }

    /* uses str as a set of delimiters of size 1 and splits accordingly
        as for maxSplits, the same rules as those from split apply */
    splitMulti: func(str: This, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer splitMulti(str _buffer, maxSplits) )

    }

    split: func~withChar(c: Char, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withChar(c, maxSplits) )
    }

    /** split s and return *all* elements, including empties */
    split: func~withStringWithoutMaxSplits(s: This) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split ( s, -1) )
    }

    split: func~withCharWithoutMaxSplits(c: Char) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withCharWithoutMaxSplits(c) )
    }

    split: func~withStringWithEmpties( s: This, empties: Bool) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withStringWithEmpties (s, empties ? -1 : 0 ) )
    }

    split: func~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withCharWithEmpties( c , empties ) )
    }

    /** splits a string into an ArrayList, maxSplits denotes max elements of returned list
        if it is > 0, it will be splitted maxSplits -1 times, and in the last element the rest of the string will be held.
        if maxSplits is negative, it will return all elements, if 0 it will return all non-empty elements.
        pretty much the same as in java.*/
    // FIXME untested!
    split: func ~str (delimiter: This, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~buf ( delimiter _buffer, maxSplits ) )
    }

    /** characters lowercased (if possible). */
    toLower: func -> This {
        result := clone()
        result _buffer toLower()
        result
    }

    /** characters uppercased (if possible). */
    toUpper: func  -> This{
        result := clone()
        result _buffer toUpper()
        result
    }

    /** return the index of *c*, starting at 0. If *this* does not contain *c*, return -1. */
    indexOf: func ~charZero (c: Char) -> SSizeT { _buffer indexOf~charZero(c) }

    /** return the index of *c*, but only check characters ``start..length``.
        However, the return value is the index of the *c* relative to the
        string's beginning. If *this* does not contain *c*, return -1. */
    indexOf: func ~char (c: Char, start: SizeT) -> SSizeT { _buffer indexOf~char(c, start) }

    /** return the index of *s*, starting at 0. If *this* does not contain *s*,
        return -1. */
    indexOf: func ~stringZero (s: This) -> SSizeT { _buffer indexOf~bufZero (s _buffer) }

    /** return the index of *s*, but only check characters ``start..length``.
        However, the return value is relative to the *this*' first character.
        If *this* does not contain *c*, return -1. */
    indexOf: func ~buf (s: This, start: Int) -> SSizeT { _buffer indexOf~buf(s buffer, start) }

        /** return *true* if *this* contains the character *c* */
    contains?: func ~char (c: Char) -> Bool { _buffer contains?~char (c) }

    /** return *true* if *this* contains the string *s* */
    contains?: func ~string (s: This) -> Bool { _buffer contains?~buf (s _buffer) }

    /** all characters contained by *s* stripped at both ends. */
    trimMulti: func ~pointer (s: Char*, sLength: SizeT) -> This {
        result := clone()
        result _buffer trimMulti(s, sLength)
        result
    }

    trimMulti: func ~string(s : This) -> This {
        result := clone()
        result buffer trimMulti(s _buffer)
        result
    }

    trim: func~pointer(s: Char*, sLength: SizeT) -> This {
        result := clone()
        result _buffer trim~pointer(s, sLength)
        result
    }

    trim: func ~string(s : This) -> This {
        result := clone()
        result _buffer trim~buf(s _buffer)
        result
    }

    /** *c* characters stripped at both ends. */
    trim: func ~char (c: Char) -> This {
        result := clone()
        result _buffer trim~char(c)
        result
    }

    /** whitespace characters (space, CR, LF, tab) stripped at both ends. */
    trim: func ~whitespace -> This {
        result := clone()
        result _buffer trim~whitespace()
        result
    }

    /** space characters (ASCII 32) stripped from the left side. */
    trimLeft: func ~space {
        result := clone()
        result _buffer trimLeft~space()
        result
    }

    /** *c* character stripped from the left side. */
    trimLeft: func ~char (c: Char) {
        result := clone()
        result _buffer trimLeft~char(c)
        result
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~string (s: This) {
        result := clone()
        result _buffer trimLeft~buf(s)
        result
    }

    /** all characters contained by *s* stripped from the left side. either from *this* or a clone */
    trimLeft: func ~pointer (s: Char*, sLength: SizeT) {
        result := clone()
        result _buffer trimLeft~pointer(s, sLength)
        result
    }

    /** space characters (ASCII 32) stripped from the right side. */
    trimRight: func ~space -> This {
        result := clone()
        result _buffer trimRight~space()
        result
    }

    /** *c* characters stripped from the right side. */
    trimRight: func ~char (c: Char) -> This {
        result := clone()
        result _buffer trimRight~char(c)
        result
    }

    /** strip *this* with all characters contained by *s* from the right side. */
    trimRight: func ~string (s: This) -> This{
        result := clone()
        result _buffer trimRight~buf( s _buffer )
        result
    }

    /** return (a copy of) *this* with all characters contained by *s* stripped
        from the right side. */
    trimRight: func ~pointer (s: Char*, sLength: SizeT) -> This{
        result := clone()
        result _buffer trimRight~pointer(s, sLength)
        result
    }

    /** reverses string in place */
    reverse: func -> This {
        result := clone()
        result _buffer reverse()
        result
    }

    /** return the number of *what*'s occurences in *this*. */
    count: func (what: Char) -> SizeT { _buffer count (what) }

    /** return the number of *what*'s non-overlapping occurences in *this*. */
    count: func ~string (what: This) -> SizeT { _buffer count~buf(what _buffer) }

    /** return the first character of *this*. If *this* is empty, 0 is returned. */
    first: func -> Char { _buffer first() }

    /** return the index of the last character of *this*. If *this* is empty,
        -1 is returned. */
    lastIndex: func -> SSizeT { _buffer lastIndex() }

    /** return the last character of *this*. */
    last: func -> Char { _buffer last() }

    /** return the index of the last occurence of *c* in *this*.
        If *this* does not contain *c*, return -1. */
    lastIndexOf: func (c: Char) -> SSizeT { _buffer lastIndexOf(c) }

    /** print *this* to stdout without a following newline. Flush stdout. */
    print: func { _buffer print() }

    /** print *this* followed by a newline. */
    println: func { _buffer println() }

    /** convert the string's contents to Int. */
    toInt: func -> Int                       { _buffer toInt() }
    toInt: func ~withBase (base: Int) -> Int { _buffer toInt~withBase(base) }

    /** convert the string's contents to Long. */
    toLong: func -> Long                        { _buffer toLong() }
    toLong: func ~withBase (base: Long) -> Long { _buffer toLong~withBase(base) }

    /** convert the string's contents to Long Long. */
    toLLong: func -> LLong                         { _buffer toLLong() }
    toLLong: func ~withBase (base: LLong) -> LLong { _buffer toLLong~withBase(base) }

    /** convert the string's contents to Unsigned Long. */
    toULong: func -> ULong                         { _buffer toULong() }
    toULong: func ~withBase (base: ULong) -> ULong { _buffer toULong~withBase(base) }

    /** convert the string's contents to Float. */
    toFloat: func -> Float                         { _buffer toFloat() }

    /** convert the string's contents to Double. */
    toDouble: func -> Double                       { _buffer toDouble() }

    /** convert the string's contents to Long Double. */
    toLDouble: func -> LDouble                     { _buffer toLDouble() }

    iterator: func -> BufferIterator<Char> {
        _buffer iterator()
    }

    forward: func -> BufferIterator<Char> {
        _buffer forward()
    }

    backward: func -> BackIterator<Char> {
        _buffer backward()
    }

    backIterator: func -> BufferIterator<Char> {
        _buffer backIterator()
    }

    format: final func ~ str (...) -> This {
        result := clone()
        list:VaList
        fmt := result buffer

        va_start(list, this)
        length := vsnprintf(null, 0, (fmt data), list)
        va_end(list)

        copy := Buffer new(length)

        va_start(list, this )
        vsnprintf((copy buffer data), length + 1, (fmt data), list)
        va_end(list)
        This new~withBuffer(copy)
    }
}


operator implicit as (s: String) -> Char* {
    s _buffer data
}

operator implicit as (c: Char*) -> String {
    return c ? String new (c, strlen(c)) : null
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

// lame static function to be called by int main, so i dont have to metaprogram it
import structs/ArrayList

strArrayListFromCString: func (argc: Int, argv: Char**) -> ArrayList<String> {
    result := ArrayList<String> new ()
    for (i in 0..argc) {
        s := String new ((argv[i]) as CString, (argv[i]) as CString length())
        result add( s )
    }
    result
}