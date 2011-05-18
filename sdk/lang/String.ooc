
/**
 * The String class represents character strings.
 * 
 * The String class is immutable by default, this means every writing operation
 * is done on a clone, which is then returned
 *
 * @author (rofl0r) - rewrite to make String a class, make it immutable etc.
 * @author Amos Wenger (nddrylliog) - initial SDK work
 * @author Scott Olson (tsion/_scott)
 */
String: class extends Iterable<Char> {

    /**
     * Underlying buffer used to store a string's data.
     * Avoid direct access, as it breaks immutability.
     */
    _buffer: Buffer

    /** Size of this string, in bytes */
    size: SSizeT {
        get {
            _buffer size
        }
    }

    init: func ~withBuffer(=_buffer) {}

    init: func ~withCStr (s: CString) {
        init(s, s length())
    }

    init: func ~withCStrAndLength(s: CString, length: SizeT) {
        _buffer = Buffer new(s, length)
    }

    length: func -> SizeT {
        _buffer size
    }

    equals?: final func (other: This) -> Bool {
        if(this == null) return (other == null)
        if(other == null) return false
        _buffer equals?(other _buffer)
    }

    clone: func -> This {
        new(_buffer clone())
    }

    substring: func ~tillEnd (start: SizeT) -> This { substring(start, size) }

    substring: func (start: SizeT, end: SizeT) -> This{
        result := _buffer clone()
        result substring(start, end)
        result toString()
    }

    times: func (count: SizeT) -> This {
        result := _buffer clone(size * count)
        result times(count)
        result toString()
    }

    append: func ~str (other: This) -> This {
        if(!other) return this
        result := _buffer clone(size + other size)
        result append (other _buffer)
        result toString()
    }

    append: func ~char (other: Char) -> This {
        result := _buffer clone(size + 1)
        result append(other)
        result toString()
    }

    append: func ~cStr (other: CString) -> This {
        l := other length()
        result := _buffer clone(size + l)
        result append(other, l)
        result toString()
    }

    prepend: func ~str (other: This) -> This{
        result := _buffer clone()
        result prepend(other _buffer)
        result toString()
    }

    prepend: func ~char (other: Char) -> This {
        result := _buffer clone()
        result prepend(other)
        result toString()
    }

    empty?: func -> Bool { _buffer empty?() }

    startsWith?: func (s: This) -> Bool { _buffer startsWith? (s _buffer) }

    startsWith?: func ~char(c: Char) -> Bool { _buffer startsWith?(c) }

    endsWith?: func (s: This) -> Bool { _buffer endsWith? (s _buffer) }

    endsWith?: func ~char(c: Char) -> Bool { _buffer endsWith?(c) }

    find : func (what: This, offset: SSizeT, searchCaseSensitive := true) -> SSizeT {
        _buffer find(what _buffer, offset, searchCaseSensitive)
    }

    findAll: func ( what : This, searchCaseSensitive := true) -> ArrayList <SizeT> {
        _buffer findAll(what _buffer, searchCaseSensitive)
    }

    replaceAll: func ~str (what, whit : This, searchCaseSensitive := true) -> This {
        result := _buffer clone()
        result replaceAll (what _buffer, whit _buffer, searchCaseSensitive)
        result toString()
    }

    replaceAll: func ~char(oldie, kiddo: Char) -> This {
        (_buffer clone()) replaceAll~char(oldie, kiddo). toString()
    }
    
    map: func (f: Func (Char) -> Char) -> This {
        (_buffer clone()) map(f). toString()
    }

    _bufArrayListToStrArrayList: func (x: ArrayList<Buffer>) -> ArrayList<This> {
        result := ArrayList<This> new( x size )
        for (i in x) result add (i toString())
        result
    }

    toLower: func -> This {
        (_buffer clone()) toLower(). toString()
    }

    toUpper: func  -> This{
        (_buffer clone()) toUpper(). toString()
    }

    indexOf: func ~char (c: Char, start: SSizeT = 0) -> SSizeT { _buffer indexOf(c, start) }

    indexOf: func ~string (s: This, start: SSizeT = 0) -> SSizeT { _buffer indexOf(s _buffer, start) }

    contains?: func ~char (c: Char) -> Bool { _buffer contains?(c) }

    contains?: func ~string (s: This) -> Bool { _buffer contains?(s _buffer) }

    trim: func~pointer(s: Char*, sLength: SizeT) -> This {
        result := _buffer clone()
        result trim~pointer(s, sLength)
        result toString()
    }

    trim: func ~string(s : This) -> This {
        result := _buffer clone()
        result trim~buf(s _buffer)
        result toString()
    }

    trim: func ~char (c: Char) -> This {
        result := _buffer clone()
        result trim~char(c)
        result toString()
    }

    trim: func ~whitespace -> This {
        result := _buffer clone()
        result trim~whitespace()
        result toString()
    }

    trimLeft: func ~space -> This {
        result := _buffer clone()
        result trimLeft~space()
        result toString()
    }

    trimLeft: func ~char (c: Char) -> This {
        result := _buffer clone()
        result trimLeft~char(c)
        result toString()
    }

    trimLeft: func ~string (s: This) -> This {
        result := _buffer clone()
        result trimLeft~buf(s _buffer)
        result toString()
    }

    trimLeft: func ~pointer (s: Char*, sLength: SizeT) -> This {
        result := _buffer clone()
        result trimLeft~pointer(s, sLength)
        result toString()
    }

    trimRight: func ~space -> This {
        result := _buffer clone()
        result trimRight~space()
        result toString()
    }

    trimRight: func ~char (c: Char) -> This {
        result := _buffer clone()
        result trimRight~char(c)
        result toString()
    }

    trimRight: func ~string (s: This) -> This{
        result := _buffer clone()
        result trimRight~buf( s _buffer )
        result toString()
    }

    trimRight: func ~pointer (s: Char*, sLength: SizeT) -> This{
        result := _buffer clone()
        result trimRight~pointer(s, sLength)
        result toString()
    }

    reverse: func -> This {
        result := _buffer clone()
        result reverse()
        result toString()
    }

    count: func (what: Char) -> SizeT { _buffer count (what) }

    count: func ~string (what: This) -> SizeT { _buffer count~buf(what _buffer) }

    lastIndexOf: func (c: Char) -> SSizeT { _buffer lastIndexOf(c) }

    print: func { _buffer print() }

    println: func { if(_buffer != null) _buffer println() }
    
    println: func ~withStream (stream: FStream) { if(_buffer != null) _buffer println(stream) }

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

    cformat: final func ~str (...) -> This {
        list: VaList
        va_start(list, this)
        numBytes := vsnprintf(null, 0, _buffer data, list)
        va_end(list)

        copy := Buffer new(numBytes)
        copy size = numBytes
        va_start(list, this)
        vsnprintf(copy data, numBytes + 1, _buffer data, list)
        va_end(list)
        
        new(copy)
    }

    toCString: func -> CString { _buffer data as CString }

}

/* conversions C world -> String */

operator implicit as (c: Char*) -> String {
    c ? String new(c, strlen(c)) : null
}

operator implicit as (c: CString) -> String {
    c ? String new(c, strlen(c)) : null
}

/* conversions String -> C world */

operator implicit as (s: String) -> Char* {
    s ? s toCString() : null
}

operator implicit as (s: String) -> CString {
    s ? s toCString() : null
}

/* Comparisons */

operator == (str1: String, str2: String) -> Bool {
    str1 equals?(str2)
}

operator != (str1: String, str2: String) -> Bool {
    !str1 equals?(str2)
}

/* Access and modification */

operator [] (string: String, index: SSizeT) -> Char {
    string _buffer [index]
}

operator [] (string: String, range: Range) -> String {
    string substring(range min, range max)
}

/* Concatenation and other fun stuff */

operator * (string: String, count: SizeT) -> String {
    string times(count)
}

operator + (left, right: String) -> String {
    left append(right)
}

operator + (left: String, right: CString) -> String {
    left append(right)
}

operator + (left: String, right: Char) -> String {
    left append(right)
}

operator + (left: Char, right: String) -> String {
    right prepend(left)
}

// constructor to be called from string literal initializers
makeStringLiteral: func (str: CString, strLen: SizeT) -> String {
    String new(Buffer new(str, strLen, true))
}

// lame static function to be called by int main, so i dont have to metaprogram it
import structs/ArrayList

strArrayListFromCString: func (argc: Int, argv: Char**) -> ArrayList<String> {
    result := ArrayList<String> new()
    argc times(|i| result add(argv[i] as CString toString()))
    result
}

strArrayListFromCString: func~hack (argc: Int, argv: String*) -> ArrayList<String> {
    strArrayListFromCString(argc, argv as Char**)
}

cStringPtrToStringPtr: func (cstr: CString*, len: SizeT) -> String* {
    // Mostly to allow main to accept String*
    // func-name sucks, I am open to all suggestions 

    toRet: String* = gc_malloc(Pointer size * len) // otherwise the pointers are stack-allocated 
    for (i in 0..len) {
        toRet[i] = makeStringLiteral(cstr[i], cstr[i] length())
    }
    toRet
}
