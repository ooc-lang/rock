use siphash

siphash24: extern proto func (src: Pointer, size: ULong, key: Char*) -> UInt64

SipHash: class {

    hash: static func (src: Pointer, size: ULong) -> UInt64 {
        dummyKey := [ '\0', '\x01', '\x02', '\x03', '\x04', '\x05', '\x06', '\x07', '\x08', '\x09', '\x0a', '\x0b', '\x0c', '\x0d', '\x0e', '\x0f' ] as Char*
        siphash24(src, size, dummyKey)
    }

    hash: static func ~string (src: String) -> UInt64 {
        hash(src toCString(), src size)
    }

}

