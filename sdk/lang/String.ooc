/*  The String class is immutable by default, this means every writing operation
    is done on a clone, which is then returned

    most work done by rofl0r

    */

String: class {

    // accessing this member directly can break immutability, so you should avoid it.
    _buffer: Buffer

    size: SizeT {
        get {
            _buffer size
        }
    }

    init: func { _buffer = Buffer new() }

    init: func ~withBuffer(b: Buffer) { _buffer = b }

    init: func ~withChar(c: Char) { _buffer = Buffer new~withChar(c) }

    init: func ~withLength (length: SizeT) { _buffer = Buffer new~withLength(length) }

    init: func ~withString (s: String) { _buffer = s _buffer clone() }

    init: func ~withCStr (s : CString) { _buffer = Buffer new~withCStr(s) }

    init: func ~withCStrAndLength(s : CString, length: SizeT) { _buffer = Buffer new~withCStrAndLength(s, length) }

    length: func -> SizeT { _buffer size }

    equals?: func (other: This) -> Bool { other != null && _buffer equals? (other _buffer) }

    charAt: func (index: SizeT) -> Char { _buffer charAt(index) }

    clone: func -> This {
        This new( _buffer clone() )
    }

    substring: func ~tillEnd (start: SizeT) -> This { substring(start, _buffer size) }

    substring: func (start: SizeT, end: SizeT) -> This{
        result :=clone()
        result _buffer substring(start, end)
        result
    }

    times: func (count: SizeT) -> This {
        result := clone()
        result _buffer times(count)
        result
    }

    append: func ~str(other: This) -> This{
        result := clone()
        result _buffer append~buf(other _buffer)
        result
    }

    append: func ~char (other: Char) -> This {
        result := clone()
        result _buffer append~char(other)
        result
    }

    prepend: func ~str (other: This) -> This{
        result := clone()
        result _buffer prepend~buf(other _buffer)
        result
    }

    prepend: func ~char (other: Char) -> This {
        result := clone()
        result _buffer prepend~char(other)
        result
    }

    compare: func (other: This, start, length: SizeT) -> Bool {
        _buffer compare(other _buffer, start, length)
    }

    compare: func ~implicitLength (other: This, start: SizeT) -> Bool {
        _buffer compare(other _buffer, start)
    }

    compare: func ~whole (other: This) -> Bool {
        _buffer compare(other _buffer)
    }

    empty?: func -> Bool { _buffer empty?() }

    startsWith?: func (s: This) -> Bool { _buffer startsWith? (s _buffer) }

    startsWith?: func ~char(c: Char) -> Bool { _buffer startsWith?~char(c) }

    endsWith?: func (s: This) -> Bool { _buffer endsWith? (s _buffer) }

    endsWith?: func ~char(c: Char) -> Bool { _buffer endsWith?~char (c) }

    find : func (what: This, offset: SSizeT) -> SSizeT { _buffer find( what _buffer, offset) }

    find : func ~withCase (what: This, offset: SSizeT, searchCaseSensitive : Bool) -> SSizeT {
        _buffer find~withCase( what _buffer, offset, searchCaseSensitive )
    }

    findAll: func ( what : This) -> ArrayList <SizeT> { _buffer findAll( what _buffer ) }

    findAll: func ~withCase ( what : This, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        _buffer findAll~withCase( what _buffer, searchCaseSensitive )
    }

    replaceAll: func ~str (what, whit : This) -> This {
        result := clone()
        _buffer replaceAll~buf (what _buffer, whit _buffer)
        result
    }

    replaceAll: func ~strWithCase (what, whit : This, searchCaseSensitive: Bool) -> This {
        result := clone()
        _buffer replaceAll~bufWithCase (what _buffer, whit _buffer, searchCaseSensitive)
        result
    }

    replaceAll: func ~char(oldie, kiddo: Char) -> This {
        result := clone()
        _buffer replaceAll~char(oldie, kiddo)
        result
    }

    _bufArrayListToStrArrayList: func ( x : ArrayList<Buffer> ) -> ArrayList<This> {
        result := ArrayList<This> new( x size() )
        for (i in x) result add (This new~withBuffer( i ) )
        result
    }

    splitMulti: func(str: This, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer splitMulti(str _buffer, maxSplits) )
    }

    split: func~withChar(c: Char, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withChar(c, maxSplits) )
    }

    split: func~withStringWithoutMaxSplits(s: This) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split ( s _buffer, -1) )
    }

    split: func~withCharWithoutMaxSplits(c: Char) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withCharWithoutMaxSplits(c) )
    }

    split: func~withStringWithEmpties( s: This, empties: Bool) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withStringWithEmpties (s _buffer, empties ) )
    }

    split: func~withCharWithEmpties(c: Char, empties: Bool) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~withCharWithEmpties( c , empties ) )
    }

    split: func ~str (delimiter: This, maxSplits: SSizeT) -> ArrayList <This> {
        _bufArrayListToStrArrayList( _buffer split~buf ( delimiter _buffer, maxSplits ) )
    }

    toLower: func -> This {
        result := clone()
        result _buffer toLower()
        result
    }

    toUpper: func  -> This{
        result := clone()
        result _buffer toUpper()
        result
    }

    indexOf: func ~charZero (c: Char) -> SSizeT { _buffer indexOf~charZero(c) }

    indexOf: func ~char (c: Char, start: SizeT) -> SSizeT { _buffer indexOf~char(c, start) }

    indexOf: func ~stringZero (s: This) -> SSizeT { _buffer indexOf~bufZero (s _buffer) }

    indexOf: func ~buf (s: This, start: Int) -> SSizeT { _buffer indexOf~buf(s _buffer, start) }

    contains?: func ~char (c: Char) -> Bool { _buffer contains?~char (c) }

    contains?: func ~string (s: This) -> Bool { _buffer contains?~buf (s _buffer) }

    trimMulti: func ~pointer (s: Char*, sLength: SizeT) -> This {
        result := clone()
        result _buffer trimMulti(s, sLength)
        result
    }

    trimMulti: func ~string(s : This) -> This {
        result := clone()
        result _buffer trimMulti(s _buffer)
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

    trim: func ~char (c: Char) -> This {
        result := clone()
        result _buffer trim~char(c)
        result
    }

    trim: func ~whitespace -> This {
        result := clone()
        result _buffer trim~whitespace()
        result
    }

    trimLeft: func ~space -> This {
        result := clone()
        result _buffer trimLeft~space()
        result
    }

    trimLeft: func ~char (c: Char) -> This {
        result := clone()
        result _buffer trimLeft~char(c)
        result
    }

    trimLeft: func ~string (s: This) -> This {
        result := clone()
        result _buffer trimLeft~buf(s _buffer)
        result
    }

    trimLeft: func ~pointer (s: Char*, sLength: SizeT) -> This {
        result := clone()
        result _buffer trimLeft~pointer(s, sLength)
        result
    }

    trimRight: func ~space -> This {
        result := clone()
        result _buffer trimRight~space()
        result
    }

    trimRight: func ~char (c: Char) -> This {
        result := clone()
        result _buffer trimRight~char(c)
        result
    }

    trimRight: func ~string (s: This) -> This{
        result := clone()
        result _buffer trimRight~buf( s _buffer )
        result
    }

    trimRight: func ~pointer (s: Char*, sLength: SizeT) -> This{
        result := clone()
        result _buffer trimRight~pointer(s, sLength)
        result
    }

    reverse: func -> This {
        result := clone()
        result _buffer reverse()
        result
    }

    count: func (what: Char) -> SizeT { _buffer count (what) }

    count: func ~string (what: This) -> SizeT { _buffer count~buf(what _buffer) }

    first: func -> Char { _buffer first() }

    lastIndex: func -> SSizeT { _buffer lastIndex() }

    last: func -> Char { _buffer last() }

    lastIndexOf: func (c: Char) -> SSizeT { _buffer lastIndexOf(c) }

    print: func { _buffer print() }

    println: func { if(_buffer != null) _buffer println() }

    toInt: func -> Int                       { _buffer toInt() }
    toInt: func ~withBase (base: Int) -> Int { _buffer toInt~withBase(base) }
    toLong: func -> Long                        { _buffer toLong() }
    toLong: func ~withBase (base: Long) -> Long { _buffer toLong~withBase(base) }
    toLLong: func -> LLong                         { _buffer toLLong() }
    toLLong: func ~withBase (base: LLong) -> LLong { _buffer toLLong~withBase(base) }
    toULong: func -> ULong                         { _buffer toULong() }
    toULong: func ~withBase (base: ULong) -> ULong { _buffer toULong~withBase(base) }
    toFloat: func -> Float                         { _buffer toFloat() }
    toDouble: func -> Double                       { _buffer toDouble() }
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
        fmt := result _buffer

        va_start(list, this)
        length := vsnprintf(null, 0, (fmt data), list)
        va_end(list)

        copy := Buffer new(length)

        va_start(list, this )
        vsnprintf((copy data), length + 1, (fmt data), list)
        va_end(list)
        This new~withBuffer(copy)
    }

    printf: final func ~str (...) -> This{
        result := clone()
        list: VaList

        va_start(list, this )
        vprintf((result _buffer data), list)
        va_end(list)
        return result
    }

     printfln: final func ~str (...) -> This {
        result := append('\n')
        list: VaList

        va_start(list, this )
        vprintf((result _buffer data), list)
        va_end(list)
        return result
    }

    toCString: func -> CString { _buffer data as CString }

}

operator implicit as (s: String) -> Char* {
    s _buffer data
}

operator implicit as (c: Char*) -> String {
    return c ? String new (c as CString, strlen(c)) : null
}

operator implicit as (c: CString) -> String {
    return c ? String new (c, strlen(c)) : null
}

operator implicit as (s: String) -> CString {
    s _buffer data as CString
}



operator == (str1: String, str2: String) -> Bool {
    assert (str1 != null)
    assert (str2 != null)
    return str1 _buffer  ==  str2 _buffer
}

operator != (str1: String, str2: String) -> Bool {
    assert (str1 != null)
    assert (str2 != null)
    return str1 _buffer  !=  str2 _buffer
}

operator [] (string: String, index: SizeT) -> Char {
    assert (string != null)
    string _buffer [index]
}

operator []= (string: String, index: SizeT, value: Char) {
    Exception new(String, "Writing to a String breaks immutability! use a Buffer instead!" format(index, string length())) throw()
}

operator [] (string: String, range: Range) -> String {
    assert (string != null)
    string substring(range min, range max)
}

operator * (string: String, count: Int) -> String {
    assert (string != null)
    return string times(count)
}

operator + (left, right: String) -> String {
    assert ((left != null) && (right != null))
    b := left _buffer clone ( left size + right size )
    b.append(right _buffer)
    return String new~withBuffer(b)
}

operator + (left: String, right: CString) -> String {
    assert ((left != null) && (right != null))
    l := right length()
    b:= left _buffer clone(left size + l)
    b append(right, l)
    b toString()
}

operator + (left: String, right: Char) -> String {
    assert ((left != null))
    left append(right)
}

operator + (left: Char, right: String) -> String {
    assert ((right != null))
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

/* damn, there's one probelm left. rock makes
source/rock/rock.ooc:4:12 ERROR No such function strArrayListFromCString(Int, String*)
 i make this quick hack here
 */
strArrayListFromCString: func~hack (argc: Int, argv: String*) -> ArrayList<String> {
    strArrayListFromCString(argc, argv as Char**)
}


