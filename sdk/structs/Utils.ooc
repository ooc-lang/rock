Utils: class {

    stringEquals: static func <K> (k1, k2: K) -> Bool {
        assert(K == String)
        k1 as String equals?(k2 as String)
    }

    cstringEquals: static func <K> (k1, k2: K) -> Bool {
        k1 as CString == k2 as CString
    }


    pointerEquals: static func <K> (k1, k2: K) -> Bool {
        k1 as Pointer == k2 as Pointer
    }

    intEquals: static func <K> (k1, k2: K) -> Bool {
        k1 as Int == k2 as Int
    }

    charEquals: static func <K> (k1, k2: K) -> Bool {
        k1 as Char == k2 as Char
    }

    /** used when we don't have a custom comparing function for the key type */
    genericEquals: static func <K> (k1, k2: K) -> Bool {
        // FIXME rock should turn == between generic vars into a memcmp itself
        memcmp(k1, k2, K size) == 0
    }

    intHash: static func <K> (key: K) -> SizeT {
        result: SizeT = key as Int
        return result
    }

    pointerHash: static func <K> (key: K) -> SizeT {
        return (key as Pointer) as SizeT
    }

    charHash: static func <K> (key: K) -> SizeT {
        // both casts are necessary
        // Casting 'key' directly to UInt would deref a pointer to UInt
        // which would read random memory just after the char, which is not a good idea..
        return (key as Char) as SizeT
    }

    /**
       Port of Austin Appleby's Murmur Hash implementation
       http://code.google.com/p/smhasher/

       :param: key The key to hash
       :param: seed The seed value
     */
    murmurHash: static func <K> (keyTagazok: K) -> SizeT {

        seed: SizeT = 1 // TODO: figure out what makes a good seed value?

        len := K size
        m = 0x5bd1e995 : const SizeT
        r = 24 : const SSizeT
        l := len

        h : SizeT = seed ^ len
        data := (keyTagazok&) as Octet*

        while (true) {
            k := (data as SizeT*)@

            k *= m
            k ^= k >> r
            k *= m

            h *= m
            h ^= k

            data += 4
            if(len < 4) break
            len -= 4
        }

        t := 0

        if(len == 3) h ^= data[2] << 16
        if(len == 2) h ^= data[1] << 8
        if(len == 1) h ^= data[0]

        t *= m; t ^= t >> r; t *= m; h *= m; h ^= t;
        l *= m; l ^= l >> r; l *= m; h *= m; h ^= l;

        h ^= h >> 13
        h *= m
        h ^= h >> 15

        return h
    }

    /**
     * khash's ac_X31_hash_string
     * http://attractivechaos.awardspace.com/khash.h.html
     * @access private
     * @param s The string to hash
     * @return UInt
     */
    ac_X31_hash: static func <K> (key: K) -> SizeT {
        assert(key as Pointer != null)
        s : Char* = (K == String) ? (key as String) toCString() as Char* : key as Char*
        h = s@ : SizeT
        if (h) {
            s += 1
            while (s@) {
                h = (h << 5) - h + s@
                s += 1
            }
        }
        return h
    }

    /* this function seem is called by List */
    getStandardEquals: static func <T> (T: Class) -> Func <T> (T, T) -> Bool {
        // choose comparing function for key type
        if(T == String) {
            Utils stringEquals
        } else if(T == CString) {
            Utils cstringEquals
        } else if(T size == Pointer size) {
            Utils pointerEquals
        } else if(T size == UInt size) {
            Utils intEquals
        } else if(T size == Char size) {
            Utils charEquals
        } else {
            Utils genericEquals
        }
    }

    getStandardHashFunc: static func <T> (T: Class) -> Func <T> (T) -> SizeT {
        if(T == String || T == CString) {
            Utils ac_X31_hash
        } else if(T size == Pointer size) {
            Utils pointerHash
        } else if(T size == UInt size) {
            Utils intHash
        } else if(T size == Char size) {
            Utils charHash
        } else {
            Utils murmurHash
        }
    }
}

