import io/[Reader, BinarySequence]
import structs/[Bag, HashBag, Stack]

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

Min: class {
    init: func {}
}

Max: class {
    init: func {}
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
        read := seq bytesRead
        sizes push(seq s32() + read)
        doc
    }

    pushArray: func -> Bag {
        arr := Bag new()
        documents push(arr)
        read := seq bytesRead
        sizes push(seq s32() + read)
        arr
    }

    popDocument: func {
        documents pop()
        sizes pop()
    }

    put: func <T> (key: String, value: T, index: SizeT) {
        doc := documents peek(index)
        if(doc instanceOf?(Bag))
            doc as Bag add(value) // `key` can be omitted here -- the keys have to be ascending anyway
        else
            doc as HashBag put(key, value)
    }

    put: func ~top <T> (key: String, value: T) {
        put(key, value, 1)
    }

    readElement: func {
        if(seq bytesRead == sizes peek() - 1) {
            // a document was finished!
        }
        id := seq u8()
        match (id) {
            case 0x00 => {
                 // is it the root?
                if(documents size() == 1) {
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
            case 0x0d => readString() // TODO?
            case 0x0e => readString() // ^
            case 0x0f => readString() // ^
            case 0x10 => readInt32()
            case 0x11 => readInt64()
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
        n println()
        n
    }

    readDouble: func {
        name := readName()
        value := seq float64()
        put(name, value)
    }

    readString: func {
        name := readName()
        value := seq pascalString(4) // TODO: this will interpret the first byte as unsigned, while bson says it's signed. problems?
        // TODO: the value can contain null bytes -- wait for the new String!
        put(name, value)
    }

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
            if(size != size2 + 1)
                Exception new(This, "size1 %d != size2 %d + 1 for old binary subtype" format(size, size2)) throw()
            size -= 1 // because we've already read one byte
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
        value := seq s64() // signed doesn't make any sense here ... oO
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

    readMin: func {
        name := readName()
        put(name, Min new())
    }

    readMax: func {
        name := readName()
        put(name, Max new())
    }
}
