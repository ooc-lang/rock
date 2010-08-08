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

BinarySequence: class {
    data := null as Octet*
    capacity: SizeT {
        get
        set(newCapacity) {
            newData := null
            if(newCapacity > 0) {
                newData = gc_malloc(Octet size * newCapacity)
                if(data != null) {
                    memcpy(newData, data, capacity)
                }
                // TODO: we could free `data` here.
            }
            capacity = newCapacity
            data = newData
        }
    }

    index: SizeT {
        get
        set(=index) {
            // resize if needed.
            if(index >= capacity) {
                capacity += (index - capacity) + 1
            }
        }
    }

    endianness := ENDIANNESS

    init: func (=capacity) {
        
    }

    init: func ~defaultCapacity {
        init(1)
    }

    clear: func {
        capacity = 0
        index = 0
    }

    pushValue: func <T> (value: T) {
        size := T size
        capacity += size // TODO: that's not efficient :)
        if(endianness != ENDIANNESS) {
            // System is little, seq is big?
            // System is big, seq is little?
            // Reverse.
            value = reverseBytes(value)
        }
        // Just throw the value to the memory.
        memcpy(data + index, value&, size)
        index += size
    }

    toOctets: func -> (Octet*, SizeT) {
        chars := gc_malloc(Octet size * index)
        memcpy(chars, data, index)
        (chars, index)
    }
}

// calculate endianness
ENDIANNESS: static Endianness
_i := 0x10f as UInt16
// On big endian, this looks like: [ 0x01 | 0x0f ]
// On little endian, this looks like: [ 0x0f | 0x01 ]
ENDIANNESS := (_i& as UInt8*)[0] == 0x0f ? Endianness little : Endianness big

printOctets: func (chars: Octet*, length: SizeT) {
    for(i in 0..length) {
        "%.2x " format(chars[i]) print()
    }
    "" println()
}

test: func (seq: BinarySequence) {
    seq pushValue(123456789 as UInt32) .pushValue(-123123 as Int64)
    (octets, length) := seq toOctets()
    printOctets(octets, length)
}

main: func {
    seq := BinarySequence new()
    seq endianness = Endianness little
    test(seq)
    seq clear()
    seq endianness = Endianness big
    test(seq)
}

