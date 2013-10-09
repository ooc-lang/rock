BASE64_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

Base64Error: class extends Exception {
    init: func (.message) {
        super(message)
    }
}

Base64: class {
    /**
     * Convert a String to Base64 and return a String.
     *
     * TODO: Should revise the input parameters. If the sdk changes to
     * Unicode, the input type should be "stream of bytes", not "stream
     * of codepoints".
     */
    encode: static func ~string (in: String) -> String {
        encode(in _buffer data as Octet*, in length())
    }

    /**
     * Convert data at some memory location to Base64 and return a String.
     */
    encode: static func ~pointer (data: Octet*, length: SizeT) -> String {
        array: Octet[]
        array length = length
        array data = data
        encode(array)
    }

    /**
     * Convert an octet array to Base64 and return a String.
     */
    encode: static func (data: Octet[]) -> String {
        buf := Buffer new()
        i := 0
        length := data length
        leftoverOctets := length % 3
        bunch: UInt32
        while(length - i >= 3) {
            // pack 3x8 bits = 24 bits in one value.
            bunch = (data[i] << 16) | (data[i + 1] << 8) | data[i + 2]
            // unpack into 4x6 bits
            buf append(BASE64_CHARS[(bunch & 0xfc0000) >> 18]) \
               .append(BASE64_CHARS[(bunch & 0x3f000) >> 12]) \
               .append(BASE64_CHARS[(bunch & 0xfc0) >> 6]) \
               .append(BASE64_CHARS[(bunch & 0x3f)])
            i += 3
        }
        if(leftoverOctets != 0) {
            // incomplete triple-octet follows!
            // at least one octet ...
            bunch = (data[i] << 16)
            if(leftoverOctets == 2) {
                // ... but possibly two.
                bunch |= (data[i + 1] << 8)
            }
            // unpack into at least 2x6 bits ...
            buf append(BASE64_CHARS[(bunch & 0xfc0000) >> 18]) \
               .append(BASE64_CHARS[(bunch & 0x3f000) >> 12])
            if(leftoverOctets == 2) {
                // ... but possibly 3x6 bits.
                buf append(BASE64_CHARS[(bunch & 0xfc0) >> 6])
            }
            // add padding characters. If we had 3 sextets, add
            // only one, if we had 2 sextets, add two.
            (3 - leftoverOctets) times(||
                buf append("=")
            )
        }
        buf toString()
    }

    /**
     * Get the sextet value from a base64 char. For the
     * padding character "=", return 0. If the character
     * is unknown, throw a Base64Error. (internal)
     */
    getSextet: static func (chr: Char) -> UInt8 {
        sextet := match(chr) {
            case '=' => 0
            case => BASE64_CHARS indexOf(chr)
        }
        if(sextet == -1) {
            Base64Error new("%c is an invalid Base64 character." format(chr)) throw()
        }
        sextet
    }

    /**
     * Convert a Base64 String to octets and return an octet array.
     * This throws a Base64Error if the input size is not a multiple
     * of 4 or the input contains invalid characters.
     */
    decode: static func (in: String) -> Octet[] {
        length := in length()
        if(length % 4 != 0) {
            Base64Error new("%d is not a multiple of 4" format(length)) throw()
        }
        // see how many padding "=" chars we have.
        paddingChars: UInt8
        if(in endsWith?("===")) {
            Base64Error new("Incorrect padding with three '=' chars.") throw()
        } else if(in endsWith?("==")) {
            paddingChars = 2
        } else if(in endsWith?("=")) {
            paddingChars = 1
        } else {
            paddingChars = 0
        }
        // Every 4-character bunch of base64 translates
        // into 3 octets; we need to take care of the
        // padding though.
        dataSize := ((length / 4) * 3) - paddingChars
        data := Octet[dataSize] new()
        bunch: UInt32
        i := 0
        while(i < length) {
            // pack 4x6 bits into 24bit ...
            bunch = (getSextet(in[i]) << 18 |
                     getSextet(in[i + 1]) << 12 |
                     getSextet(in[i + 2]) << 6 |
                     getSextet(in[i + 3]))
            // and unpack them into 3x8 bit.
            dataStart := (i / 4) * 3
            data[dataStart] = (bunch & 0xff0000) >> 16
            // make sure we don't add the padding null octets.
            if(dataStart + 1 < dataSize) {
                data[dataStart + 1] = (bunch & 0xff00) >> 8
            }
            if(dataStart + 2 < dataSize) {
                data[dataStart + 2] = bunch & 0xff
            }
            i += 4
        }
        data
    }
}
