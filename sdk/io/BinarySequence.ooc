import io/[Reader, Writer]

Endianness: enum {
    little
    big
}

reverseBytes: func <T> (value: T) -> T {
    array := value& as Octet*
    size := T size
    reversed: T
    reversedArray := reversed& as Octet*
    for(i in 0..size) {
        reversedArray[size - i - 1] = array[i]
    }
    reversed
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
        if(endianness != ENDIANNESS) {
            // System is little, seq is big?
            // System is big, seq is little?
            // Reverse.
            value = reverseBytes(value)
        }
        array := value& as Octet*
        for(i in 0..size) {
            _pushByte(array[i])
        }
    }
}

BinarySequenceReader: class {
    reader: Reader
    endianness := ENDIANNESS

    init: func (=reader) {
    }

    pullValue: func <T> (T: Class) -> T {
        size := T size
        value: T
        array := value& as Octet*
        // pull the bytes.
        for(i in 0..size) {
            array[i] = reader read()
        }
        if(endianness == ENDIANNESS) {
            // Seq is big, system is endian?
            // System is endian, seq is big?
            // Reverse.
            value = reverseBytes(value)
        }
        value
    }
}

// calculate endianness
ENDIANNESS: static Endianness
_i := 0x10f as UInt16
// On big endian, this looks like: [ 0x01 | 0x0f ]
// On little endian, this looks like: [ 0x0f | 0x01 ]
ENDIANNESS := (_i& as UInt8*)[0] == 0x0f ? Endianness little : Endianness big
