import io/[Reader, Writer]

Endianness: enum {
    little
    big
}

formatOctets: func (data: Octet*, size: SizeT) -> String {
    buf := Buffer new(size)
    for (i in 0..size) {
        buf append("%.2x " format(data[i]))
    }
    String new(buf)
}

printOctets: func (data: Octet*, size: SizeT) {
    for (i in 0..size) {
        "%.2x " format(data[i]) print()
    }
    "" println()
}

reverseBytes: func <T> (value: T) -> T {
    array := value& as Octet*
    size := T size
    reversed: T
    reversedArray := reversed& as Octet*
    for (i in 0..size) {
        reversedArray[size - i - 1] = array[i]
    }
    reversed
}

PackingError: class extends Exception {
    init: super func
}

BinarySequenceWriter: class {
    writer: Writer
    endianness := ENDIANNESS

    init: func (=writer) {
    }

    _pushByte: func (byte: Octet) {
        writer write(byte as Char) // TODO?
    }

    pushValue: func <T> (value: T) {
        size := T size
        if (endianness != ENDIANNESS) {
            // System is little, seq is big?
            // System is big, seq is little?
            // Reverse.
            value = reverseBytes(value)
        }
        array := value& as Octet*
        for (i in 0..size) {
            _pushByte(array[i])
        }
    }

    s8: func (value: Int8) { pushValue(value) }
    s16: func (value: Int16) { pushValue(value) }
    s32: func (value: Int32) { pushValue(value) }
    s64: func (value: Int64) { pushValue(value) }
    u8: func (value: UInt8) { pushValue(value) }
    u16: func (value: UInt16) { pushValue(value) }
    u32: func (value: UInt32) { pushValue(value) }
    u64: func (value: UInt64) { pushValue(value) }
    
    pad: func (bytes: SizeT) { for (_ in 0..bytes) s8(0) }

    float32: func (value: Float) { pushValue(value) }
    float64: func (value: Double) { pushValue(value) }

    /** push it, null-terminated. */
    cString: func (value: String) {
        for (chr in value) {
            u8(chr as UInt8)
        }
        s8(0)
    }

    pascalString: func (value: String, lengthBytes: SizeT) {
        length := value length()
        match (lengthBytes) { 
            case 1 => u8(length)
            case 2 => u16(length)
            case 3 => u32(length)
            case 4 => u64(length)
        }
        for (chr in value) {
            u8(chr as UInt8)
        }
    }

    bytes: func (value: Octet*, length: SizeT) {
        for (i in 0..length) {
            u8(value[i] as UInt8)
        }
    }

    bytes: func ~string (value: String) {
        for (i in 0..value length()) {
            u8(value[i] as UInt8)
        }
    }
}

BinarySequenceReader: class {
    reader: Reader
    endianness := ENDIANNESS
    bytesRead: SizeT

    init: func (=reader) {
        bytesRead = 0
    }

    pullValue: func <T> (T: Class) -> T {
        size := T size
        bytesRead += size
        value: T
        array := value& as Octet*
        // pull the bytes.
        for (i in 0..size) {
            array[i] = reader read() as Octet
        }
        if (endianness != ENDIANNESS) {
            // Seq is big, system is endian?
            // System is endian, seq is big?
            // Reverse.
            value = reverseBytes(value)
        }
        value
    }

    s8: func -> Int8 { pullValue(Int8) }
    s16: func -> Int16 { pullValue(Int16) }
    s32: func -> Int32 { pullValue(Int32) }
    s64: func -> Int64 { pullValue(Int64) }
    u8: func -> UInt8 { pullValue(UInt8) }
    u16: func -> UInt16 { pullValue(UInt16) }
    u32: func -> UInt32 { pullValue(UInt32) }
    u64: func -> UInt64 { pullValue(UInt64) }
    skip: func (bytes: UInt32) {
        for (_ in 0..bytes)
            reader read()
    }
    float32: func -> Float { pullValue(Float) }
    float64: func -> Double { pullValue(Double) }

    /** pull it, null-terminated */
    cString: func -> String {
        buffer := Buffer new()
        while (true) {
            value := u8()
            if (value == 0)
                break
            buffer append(value as Char)
        }
        buffer toString()
    }

    pascalString: func (lengthBytes: SizeT) -> String {
        length := match (lengthBytes) {
            case 1 => u8()
            case 2 => u16()
            case 4 => u32()
            //case => Exception new(This, "Unknown length bytes length: %d" format(lengthBytes)) throw()
        }
        s := Buffer new()
        for (i in 0..length) {
            s append(u8() as Char)
        }
        String new(s)
    }

    bytes: func (length: SizeT) -> Octet* {
        value := gc_malloc(length * Octet size) as Octet*
        for (i in 0..length) {
            value[i] = u8() as Octet
        }
        value
    }
}

// calculate endianness
_i := 0x10f as UInt16
// On big endian, this looks like: [ 0x01 | 0x0f ]
// On little endian, this looks like: [ 0x0f | 0x01 ]
ENDIANNESS := static (_i& as UInt8*)[0] == 0x0f ? Endianness little : Endianness big
