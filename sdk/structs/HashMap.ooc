
import ArrayList

/**
 * Container for key/value entries in the hash table
 */
HashEntry: cover {

    key, value: Pointer
    next: HashEntry*

    init: func@ ~keyVal (=key, =value) {
        next = null
    }

}

nullHashEntry: HashEntry
memset(nullHashEntry&, 0, HashEntry size)

stringEquals: func <K> (k1, k2: K) -> Bool {
    assert(K == String)
    k1 as String equals?(k2 as String)
}

cstringEquals: func <K> (k1, k2: K) -> Bool {
    k1 as CString == k2 as CString
}


pointerEquals: func <K> (k1, k2: K) -> Bool {
    k1 as Pointer == k2 as Pointer
}

intEquals: func <K> (k1, k2: K) -> Bool {
    k1 as Int == k2 as Int
}

charEquals: func <K> (k1, k2: K) -> Bool {
    k1 as Char == k2 as Char
}

/** used when we don't have a custom comparing function for the key type */
genericEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME rock should turn == between generic vars into a memcmp itself
    memcmp(k1, k2, K size) == 0
}

intHash: func <K> (key: K) -> SizeT {
    result: SizeT = key as Int
    return result
}

pointerHash: func <K> (key: K) -> SizeT {
    return (key as Pointer) as SizeT
}

charHash: func <K> (key: K) -> SizeT {
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
murmurHash: func <K> (keyTagazok: K) -> UInt32 {

    seed: UInt32 = 1 // TODO: figure out what makes a good seed value?

    len := K size
    m = 0x5bd1e995 : const UInt32 
    r = 24 : const Int32
    l := len

    h : UInt32 = seed ^ len
    data := (keyTagazok&) as UInt8*

    while (true) {
        k := (data as UInt32*)@

        k *= m
        k ^= k >> r
        k *= m

        h *= m
        h ^= k

        data += 4
        len -= 4
        if(len < 4) break
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
ac_X31_hash: func <K> (key: K) -> SizeT {
    assert(key != null)
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
getStandardEquals: func <T> (T: Class) -> Func <T> (T, T) -> Bool {
    // choose comparing function for key type
    if(T == String) {
        stringEquals
    } else if(T == CString) {
        cstringEquals
    } else if(T size == Pointer size) {
        pointerEquals
    } else if(T size == UInt size) {
        intEquals
    } else if(T size == Char size) {
        charEquals
    } else {
        genericEquals
    }
}

getStandardHashFunc: func <T> (T: Class) -> Func <T> (T) -> SizeT {
    if(T == String || T == CString) {
        ac_X31_hash
    } else if(T size == Pointer size) {
        pointerHash
    } else if(T size == UInt size) {
        intHash
    } else if(T size == Char size) {
        charHash
    } else {
        murmurHash
    }
}

/**
 * Simple hash table implementation
 */

HashMap: class <K, V> extends BackIterable<V> {

    _size, capacity: SizeT
    keyEquals: Func <K> (K, K) -> Bool
    hashKey: Func <K> (K) -> SizeT

    buckets: HashEntry[]
    keys: ArrayList<K>

    size: SizeT {
    	get {
            _size
 	}
    }

    /**
     * Returns a new hash map
     */

    init: func {
        init(3)
    }

    /**
     * Returns a hash table of a specified bucket capacity.
     * @param UInt capacity The number of buckets to use
     */
    init: func ~withCapacity (=capacity) {
        _size = 0

        buckets = HashEntry[capacity] new()
        keys = ArrayList<K> new()

        keyEquals = getStandardEquals(K)
        hashKey = getStandardHashFunc(K)

        T = V // workarounds ftw
    }

    /**
     * Retrieve the HashEntry associated with a key.
     * @param key The key associated with the HashEntry
     */
    getEntry: func (key: K, result: HashEntry*) -> Bool {
        hash : SizeT = hashKey(key) % capacity
        entry := buckets[hash]

        if(entry key == null) { return false }

        while (true) {
            if (keyEquals(entry key as K, key)) {
                if(result) {
                    result@ = entry
                }
                return true
            }

            if (entry next) {
                entry = entry next@
            } else {
                return false
            }
        }
        return false
    }

    /**
     * Returns the HashEntry associated with a key.
     * @access private
     * @param key The key associated with the HashEntry
     * @return HashEntry
     */
    getEntryForHash: func (key: K, hash: SizeT, result: HashEntry*) -> Bool {
        entry := buckets[hash]

        if(entry key == null) {
            return false
        }

        while (true) {
            if (keyEquals(entry key as K, key)) {
                if(result) {
                    result@ = entry
                }
                return true
            }

            if (entry next) {
                entry = entry next@
            } else {
                return false
            }
        }
        return false
    }

    clone: func -> HashMap<K, V> {
        copy := This<K, V> new()
        each(|k, v| copy put(k, v))
        copy
    }

    merge: func (other: HashMap<K, V>) -> HashMap<K, V> {
        c := clone()
        c merge!(other)
        c
    }

    merge!: func (other: HashMap<K, V>) -> HashMap<K, V> {
        other each(|k, v| put(k, v))
        this
    }

    /**
     * Puts a key/value pair in the hash table. If the pair already exists,
     * it is overwritten.
     * @param key The key to be hashed
     * @param value The value associated with the key
     * @return Bool
     */
    put: func (key: K, value: V) -> Bool {

        hash : SizeT = hashKey(key) % capacity

        entry : HashEntry

        if (getEntryForHash(key, hash, entry&)) {
            // replace value if the key is already existing
            memcpy(entry value, value, V size)
        } else {
            keys add(key)

            current := buckets[hash]
            if (current key != null) {
                //" - Appending!" println()
                currentPointer := (buckets data as HashEntry*)[hash]&

                while (currentPointer@ next) {
                    //" - Skipping!" println()
                    currentPointer = currentPointer@ next
                }
                newEntry := gc_malloc(HashEntry size) as HashEntry*

                newEntry@ key   = gc_malloc(K size)
                memcpy(newEntry@ key,   key, K size)

                newEntry@ value = gc_malloc(V size)
                memcpy(newEntry@ value, value, V size)

                currentPointer@ next = newEntry
            } else {
                entry key   = gc_malloc(K size)
                memcpy(entry key,   key, K size)

                entry value = gc_malloc(V size)
                memcpy(entry value, value, V size)

                entry next = null

                buckets[hash] = entry
            }
            _size += 1

            if ((_size as Float / capacity as Float) > 0.75) {
                resize(_size * (_size > 50000 ? 2 : 4))
            }
        }
        return true
    }

    /**
     * Alias of put
     */
    add: inline func (key: K, value: V) -> Bool {
        return put(key, value)
    }

    /**
     * Returns the value associated with the key. Returns null if the key
     * does not exist.
     * @param key The key associated with the value
     * @return Object
     */
    get: func (key: K) -> V {
        entry: HashEntry

        if (getEntry(key, entry&)) {
            return entry value as V
        }
        return null
    }

    /**
     * @return true if this map is empty, false if not
     */
    empty?: func -> Bool { keys empty?() }

    /**
     * Returns whether or not the key exists in the hash table.
     * @param key The key to check
     * @return Bool
     */
    contains?: func (key: K) -> Bool {
        getEntry(key, null)
    }

    /**
     * Removes the entry associated with the key
     * @param key The key to remove
     * @return Bool
     */
    remove: func (key: K) -> Bool {
        hash : SizeT = hashKey(key) % capacity

        prev = null : HashEntry*
        entry: HashEntry* = (buckets data as HashEntry*)[hash]&

        if(entry@ key == null) return false

        while (true) {
            if (keyEquals(entry@ key as K, key)) {
                if(prev) {
                    // re-connect the previous to the next one
                    prev@ next = entry@ next
                } else {
                    // just put the next one instead of us
                    if(entry@ next) {
                        buckets[hash] = entry@ next@
                    } else {
                        buckets[hash] = nullHashEntry
                    }
                }
                for (i in 0..keys size) {
                    cKey := keys get(i)
                    if(keyEquals(key, cKey)) {
                        keys removeAt(i)
                        break
                    }
                }
                _size -= 1
                return true
            }

            // do we have a next element?
            if(entry@ next) {
                // save the previous just to know where to reconnect
                prev = entry
                entry = entry@ next
            } else {
                return false
            }
        }

        return false
    }

    /**
     * Resizes the hash table to a new capacity
     * :param: _capacity The new table capacity
     * :return:
     */
    resize: func (_capacity: SizeT) -> Bool {

        /* Keep track of old settings */
        oldCapacity := capacity
        oldBuckets := buckets

        /* Clear key list and size */
        oldKeys := keys clone()
        keys clear()
        _size = 0

        /* Transfer old buckets to new buckets! */
        capacity = _capacity
        buckets = HashEntry[capacity] new()

        for (i in 0..oldCapacity) {
            entry := oldBuckets[i]
            if (entry key == null) continue

            put(entry key as K, entry value as V)

            while (entry next) {
                entry = entry next@
                put(entry key as K, entry value as V)
            }
        }

        // restore old keys to keep order
        keys = oldKeys

        return true
    }

    iterator: func -> BackIterator<V> {
        HashMapValueIterator<K, V> new(this)
    }

    backIterator: func -> BackIterator<V> {
        iter := HashMapValueIterator<K, V> new(this)
        iter index = keys getSize()
        return iter
    }

    clear: func {
        _size = 0
        for (i in 0..capacity) {
            buckets[i] = nullHashEntry
        }
        keys clear()
    }

    getSize: func -> SSizeT { _size }

    getKeys: func -> ArrayList<K> { keys }

    each: func ~withKeys (f: Func (K, V)) {
        for(key in getKeys()) {
            f(key, get(key))
        }
    }

    each: func (f: Func (V)) {
        for(key in getKeys()) {
            f(get(key))
        }
    }

}

HashMapValueIterator: class <K, T> extends BackIterator<T> {

    map: HashMap<K, T>
    index := 0

    init: func ~withMap (=map) {}

    hasNext?: func -> Bool { index < map keys size }

    next: func -> T {
        key := map keys get(index)
        index += 1
        return map get(key)
    }

    hasPrev?: func -> Bool { index > 0 }

    prev: func -> T {
        index -= 1
        key := map keys get(index)
        return map get(key)
    }

    remove: func -> Bool {
        result := map remove(map keys get(index))
        if(index <= map keys size) index -= 1
        return result
    }

}

operator [] <K, V> (map: HashMap<K, V>, key: K) -> V {
    map get(key)
}

operator []= <K, V> (map: HashMap<K, V>, key: K, value: V) {
    map put(key, value)
}
