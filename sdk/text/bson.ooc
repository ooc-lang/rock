// needed for covers from UInt64 etc.
include stdint

import io/[Reader, BinarySequence, BufferWriter, Writer]
import structs/[Bag, HashBag, Stack]
import text/EscapeSequence

BinarySubtype: enum {
    binary = 0x00
    function = 0x01
    oldBinary = 0x02
    uuid = 0x03
    md5 = 0x05
    userDefined = 0x80
}

Binary: class {
    subtype: BinarySubtype
    size: SizeT
    bytes: Octet*

    init: func (=subtype, =size, =bytes) {}
}

ObjectId: class {
    value: Octet* // pointer to 12 bytes

    init: func (=value) {}
}

Regex: class {
    pattern, options: String

    init: func (=pattern, =options) {}
}

UTCDateTime: cover from UInt64 extends UInt64 {}
//JavaScriptCode: cover from String extends String {} // TODO: support that.
//Symbol: cover from String extends String {}
//ScopedJavaScriptCode: cover from String extends String {}
Timestamp: cover from Int64 extends Int64 {}

Min: class {
    init: func {}
}

Max: class {
    init: func {}
}

writeDocument: func (w: Writer, doc: HashBag) {
    first := true
    _write := func(key, val: String) {
        if(!first)
            w write(", ")
        w write("\"%s\": %s" format(EscapeSequence escape(key), val))
        first = false
    }
    w write('{')
    for(key in doc getKeys()) {
        T := doc getClass(key)
        match T {
            case Double => _write(key, doc get(key, Double) as Double toString())
            case Float => _write(key, doc get(key, Float) as Double toString())
            case String => _write(key, "\"%s\"" format(EscapeSequence escape(doc get(key, String) as String)))
            case HashBag => {
                _write(key, "") // evil!
                writeDocument(w, doc get(key, HashBag) as HashBag)
            }
            case Bag => {
                _write(key, "") // evil!
                writeArray(w, doc get(key, Bag) as Bag)
            }
            case Binary => {
                b := doc get(key, Binary) as Binary
                _write(key, formatOctets(b bytes, b size))
            }
            case ObjectId => _write(key, formatOctets(doc get(key, ObjectId) as ObjectId value, 12))
            case Bool => _write(key, doc get(key, Bool) as Bool ? "true" : "false")
            case UTCDateTime => _write(key, doc get(key, UInt64) as UInt64 toString())
            case Pointer => _write(key, "null")
            case Regex => {
                r := doc get(key, Regex) as Regex
                _write(key, "s/%s/%s" format(r pattern, r options))
            }
            case Int32 => _write(key, doc get(key, Int32) as Int32 toString())
            case Int64 => _write(key, doc get(key, Int64) as Int64 toString())
            case Min => _write(key, "<min>")
            case Max => _write(key, "<max>")
            case => {
                Exception new("Unknown type: %s. Poke fred, he's probably stupid." format(T name)) throw()
            }
        }
    }
    w write('}')
}

writeArray: func (w: Writer, doc: Bag) {
    first := true
    _write := func(val: String) {
        if(!first)
            w write(", ")
        w write(val)
        first = false
    }
    w write('[')
    for(i in 0..doc size) {
        T := doc getClass(i)
        match T {
            case Double => _write(doc get(i, Double) as Double toString())
            case Float => _write(doc get(i, Float) as Double toString())
            case String => _write("\"%s\"" format(EscapeSequence escape(doc get(i, String) as String)))
            case HashBag => {
                _write("") // evil!
                writeDocument(w, doc get(i, HashBag) as HashBag)
            }
            case Bag => {
                _write("") // evil!
                writeArray(w, doc get(i, Bag) as Bag)
            }
            case Binary => {
                b := doc get(i, Binary) as Binary
                _write(formatOctets(b bytes, b size))
            }
            case ObjectId => _write(formatOctets(doc get(i, ObjectId) as ObjectId value, 12))
            case Bool => _write(doc get(i, Bool) as Bool ? "true" : "false")
            case UTCDateTime => _write(doc get(i, UInt64) as UInt64 toString())
            case Pointer => _write("null")
            case Regex => {
                r := doc get(i, Regex) as Regex
                _write("s/%s/%s" format(r pattern, r options))
            }
            case Int32 => _write(doc get(i, Int32) as Int32 toString())
            case Int64 => _write(doc get(i, Int64) as Int64 toString())
            case Min => _write("<min>")
            case Max => _write("<max>")
            case => {
                Exception new("Unknown type: %s. Poke fred, he's probably stupid." format(T name)) throw()
            }
        }
    }
    w write(']')
}

Parser: class {
    seq: BinarySequenceReader
    documents: Stack<Pointer> // can contain `HashBag` and `Bag`
    sizes: Stack<SizeT>
    finished := false

    document: HashBag {
        get {
            documents peek()
        }
    }

    size: SizeT {
        get {
            sizes peek()
        }
    }

    init: func (=seq) {
        documents = Stack<Pointer> new()
        sizes = Stack<SizeT> new()
    }

    readAll: func {
        pushDocument()
        while(!finished)
            readElement()
    }

    pushDocument: func -> HashBag {
        doc := HashBag new()
        documents push(doc)
        sizes push(seq s32())
        doc
    }

    pushArray: func -> Bag {
        arr := Bag new()
        documents push(arr)
        sizes push(seq s32())
        arr
    }

    popDocument: func {
        documents pop()
        sizes pop()
    }

    put: func <T> (key: String, value: T, index: SizeT) {
        doc := documents peek(index)
        if(doc instanceOf?(Bag)) {
            bag := (doc as Object) as Bag // wow that's ugly. TODO!
            bag add(value) // `key` can be omitted here -- the getKeys() have to be ascending anyway
        } else {
            doc as HashBag put(key, value)
        }
    }

    put: func ~top <T> (key: String, value: T) {
        put(key, value, 1)
    }

    readElement: func {
        /*if(seq bytesRead == sizes peek() - 1) {
            // a document was finished!
        }*/
        id := seq u8()
        match (id) {
            case 0x00 => {
                 // is it the root?
                if(documents size == 1) {
                    finished = true
                    return
                } else {
                    popDocument()
                }
            }
            case 0x01 => readDouble()
            case 0x02 => readString()
            case 0x03 => readDocument()
            case 0x04 => readArray()
            case 0x05 => readBinary()
            case 0x06 => Exception new(This, "0x06? DEPRECATED DEPRECATED DEPRECATED!") throw()
            case 0x07 => readObjectId()
            case 0x08 => readBoolean()
            case 0x09 => readUTCDateTime()
            case 0x0a => readNull()
            case 0x0b => readRegex()
            case 0x0c => Exception new(This, "0x0c? DEPRECATED DEPRECATED DEPRECATED!") throw()
            case 0x0d => readString() // JavaScriptCode()
            case 0x0e => readString() // Symbol()
            case 0x0f => readString() // ScopedJavaScriptCode()
            case 0x10 => readInt32()
            case 0x11 => readTimestamp()
            case 0x12 => readInt64()
            case 0xff => readMin()
            case 0x7f => readMax()
            case => {
                "Unknown id: %d" format(id) println()
            }
        }
    }

    readName: func -> String {
        n := seq cString()
        n
    }

    readDouble: func {
        name := readName()
        value := seq float64()
        put(name, value)
    }

    readString: func {
        name := readName()
        value := seq pascalString(4) trimRight('\0') // TODO: this will interpret the first byte as unsigned, while bson says it's signed. problems?
        // TODO: the value can contain null bytes -- wait for the new String!
        put(name, value)
    }

/*    readJavaScriptCode: func {
        name := readName()
        value := seq pascalString(4) as JavaScriptCode // TODO: this will interpret the first byte as unsigned, while bson says it's signed. problems?
        // TODO: the value can contain null bytes -- wait for the new String!
        put(name, value)
    }

    readSymbol: func {
        name := readName()
        value := seq pascalString(4) as Symbol // TODO: this will interpret the first byte as unsigned, while bson says it's signed. problems?
        // TODO: the value can contain null bytes -- wait for the new String!
        put(name, value)
    }

    readScopedJavaScriptCode: func {
        name := readName()
        value := seq pascalString(4) as ScopedJavaScriptCode // TODO: this will interpret the first byte as unsigned, while bson says it's signed. problems?
        // TODO: the value can contain null bytes -- wait for the new String!
        put(name, value)
    }*/

    readDocument: func {
        name := readName()
        value := pushDocument()
        put(name, value, 2)
    }

    readArray: func {
        name := readName()
        value := pushArray()
        put(name, value, 2)
    }

    readBinary: func {
        name := readName()
        size := seq s32()
        subtype := seq u8() as BinarySubtype
        if(subtype == BinarySubtype oldBinary) {
            // special format: i=s32() followed by `i` bytes
            size2 := seq s32()
            if(size != size2 + 4)
                Exception new(This, "size1 %d != size2 %d + 4 for old binary subtype" format(size, size2)) throw()
            size -= 4 // because we've already read one byte
        }
        bytes := seq bytes(size)
        value := Binary new(subtype, size, bytes)
        put(name, value)
    }

    readObjectId: func {
        name := readName()
        value := ObjectId new(seq bytes(12))
        put(name, value)
    }

    readBoolean: func {
        name := readName()
        value := (seq u8() == 0x01 ? true : false)
        put(name, value)
    }

    readUTCDateTime: func {
        name := readName()
        value := seq s64() as UTCDateTime // signed doesn't make any sense here ... oO
        put(name, value)
    }

    readNull: func {
        name := readName()
        put(name, null) // TODO: store it as null, really?
    }

    readRegex: func {
        name := readName()
        pattern := seq cString()
        options := seq cString()
        value := Regex new(pattern, options)
        put(name, value)
    }

    readInt32: func {
        name := readName()
        value := seq s32()
        put(name, value)
    }

    readInt64: func {
        name := readName()
        value := seq s64()
        put(name, value)
    }

    readTimestamp: func {
        name := readName()
        value := seq s64() as Timestamp
        put(name, value)
    }

    readMin: func {
        name := readName()
        put(name, Min new())
    }

    readMax: func {
        name := readName()
        put(name, Max new())
    }
}

Builder: class {
    bufSeq, globalSeq: BinarySequenceWriter
    buffer: Buffer
    bufWriter: BufferWriter

    init: func (=globalSeq) {
        buffer = Buffer new(100)
        bufWriter = BufferWriter new(buffer)
        bufSeq = BinarySequenceWriter new(bufWriter)
    }

    clearBuffer: func {
        buffer setLength(0)
    }

    writeDocument: func (doc: HashBag) {
        clearBuffer()
        // write to buffer!
        for(key in doc getKeys()) {
            U := doc getClass(key)
            _write(bufSeq, key, doc get(key, U))
        }
        // write length
        globalSeq s32(buffer size + 4 + 1) // + s32 + u8!
        globalSeq writer write(buffer)
        globalSeq u8(0)
    }

    _write: func <T> (seq: BinarySequenceWriter, name: String, obj: T) {
        match T {
            case Double => {
                seq u8(0x01) \
                      .cString(name) \
                      .float64(obj as Double)
            }
            case Float => {
                seq u8(0x01) \
                      .cString(name) \
                      .float64(obj as Float)
            }
            case String => {
                seq u8(0x02) \
                      .cString(name) \
                      .s32(obj as String length() + 1) \
                      .bytes(obj as String) \
                      .u8(0x00)
                 // including the length byte, i guess
            }
            case HashBag => { // embedded document
                // create a new temporary buffer / seq pair
                subbuf := Buffer new(100)
                subbufSeq := BinarySequenceWriter new(BufferWriter new(subbuf))
                // then, writeeeee!
                hb := obj as HashBag
                for(key in hb getKeys()) {
                    U := hb getClass(key)
                    _write(subbufSeq, key, hb get(key, U))
                }
                // then, write all that stuff to the big buffer.
                seq u8(0x03) \
                   .cString(name) \
                   .s32(subbuf size)
                seq writer write(subbuf)
                seq u8(0)
            }
            case Bag => { // array
                // create a new temporary buffer / seq pair
                subbuf := Buffer new(100)
                subbufSeq := BinarySequenceWriter new(BufferWriter new(subbuf))
                // then, writeeeee!
                bag := Bag new()
                for(i in 0..bag size) {
                    U := bag getClass(i)
                    _write(subbufSeq, i toString(), bag get(i, U))
                }
                // then, write all that stuff to the big buffer.
                seq u8(0x04) \
                   .cString(name) \
                   .s32(subbuf size)
                seq writer write(subbuf)
                seq u8(0)
            }
            case Binary => {
                bin := obj as Binary
                seq u8(0x05) \
                   .cString(name) \
                   .s32(bin size) \
                   .u8(bin subtype as Int)
                if(bin subtype == BinarySubtype oldBinary) {
                    // old binary magic // because this size thing is 4 bytes long
                    seq s32(bin size - 4) .bytes(bin bytes, bin size - 4)
                } else {
                    seq bytes(bin bytes, bin size)
                }
            }
            case ObjectId => {
                seq u8(0x07) \
                   .cString(name) \
                   .bytes(obj as ObjectId value, 12) 
            }
            case Bool => {
                seq u8(0x08) \
                   .cString(name) \
                   .u8(obj as Bool as Int)
            }
            case UTCDateTime => {
                seq u8(0x09) \
                   .cString(name) \
                   .u64(obj as UInt64)
            }
            case Pointer => { // null
                seq u8(0x0a) \
                   .cString(name) 
            }
            case Regex => {
                regex := obj as Regex
                seq u8(0x0b) \
                   .cString(name) \
                   .cString(regex pattern) \
                   .cString(regex options)
            }
            // DBPointer is omitted
/*            case JavaScriptCode => {
                seq u8(0x0d) \
                   .cString(name) \
                   .pascalString(obj as String, 4)
            }
            case Symbol => {
                seq u8(0x0e) \
                   .cString(name) \
                   .pascalString(obj as String, 4)
            }
            case ScopedJavaScriptCode => {
                seq u8(0x0f) \
                   .cString(name) \
                   .pascalString(obj as String, 4)
            }*/
            case Int32 => {
                seq u8(0x10) \
                   .cString(name) \
                   .s32(obj as Int32)
            }
            case Timestamp => {
                seq u8(0x11) \
                   .cString(name) \
                   .s64(obj as Int64) 
            }
            case Int64 => {
                seq u8(0x12) \
                   .cString(name) \
                   .s64(obj as Int64)
            }
            case Min => {
                seq u8(0xff) \
                   .cString(name)
            }
            case Max => {
                seq u8(0x7f) \
                   .cString(name)
            }
            case => {
                Exception new("Unknown type: %s. Poke fred, he's probably stupid." format(T name)) throw()
            }
        }
    }
}
