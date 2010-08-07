import io/[Writer, Reader]
/**
    Multi-Purpose Buffer class.
    This is a String, with guaranteed mutability.
    All operations will be done on the Buffer itself, instead of a clone.

    Other difference from String: the constructor will set capacity, not size.
*/

Buffer: class extends String {

    init: func {
        init(128)
    }

    init: func ~withCapa (capa: SizeT) {
        setCapacity (capa)
    }

    //init: super func ~str
    //init: super func ~withChar


    /* pretty strange function, i guess that could be replaced by substring ? */
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

        memcpy(str, data + offset, copySize)
        copySize
    }

    get: func ~chr (offset: SizeT) -> Char {
        if(offset >= size) {
            Exception new(This, "Buffer overflow! Offset is larger than buffer size.") throw()
        }
        return data[offset]
    }

    toString: func -> String {
        return this as String
    }

    /**
        reads a whole file into buffer, binary mode
    */
    fromFile: func (fileName: String) -> Bool {
        STEP_SIZE : SizeT = 4096
        file := FStream open(fileName, "rb")
        if (!file || file error()) return false
        len := file size()
        setLength ( len )

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
        buffer append(chars data, length)
        return length
    }

    /*     check out the Writer writef method for a simple varargs usage,
        this version here is mostly for internal usage (it is called by writef)
        */
    vwritef: func(fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt data, list2)
        va_end (list2)

        orgSize := buffer size
        buffer setLength( orgSize + length + 1)
        vsnprintf(buffer data as Char* + orgSize, length + 1, fmt data, list)

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
    else return true
}

/*  Test routines
    TODO use kinda builtin assert which doesnt crash when one test fails
    once unittest facility is builtin
*/
Buffer_unittest: class {

    testFile: static func {
        // this one is a bit nasty :P
        b := Buffer new(0)
        if (!b fromFile(__FILE__ ) || b size == 0) println("read failed")
        version(unix || apple) {
            if (!(b toFile("/tmp/buftest")))     println("write failed")
        }
        version(windows) {
            // FIXME use GetTemporaryFolder or however the win API calls it
            if (!(b toFile("C:\\temp\\buftest")))     println("write failed")
        }
        if (! ((c := Buffer new(0) fromFile(__FILE__) )     == b ) ) println( "comparison failed")
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
        b setLength(4)
        b size = 0
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