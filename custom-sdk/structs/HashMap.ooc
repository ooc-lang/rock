import ArrayList

/**
 * Container for key/value entries in the hash table
 */
HashEntry: class <K, V> {

    key: K
    value: V

    init: func ~keyVal (=key, =value) {}

}

stringKeyEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME those casts shouldn't be needed,
    // and this method doesn't belong here
    k1 as String equals(k2 as String)
}

/** used when we don't have a custom comparing function for the key type */
genericKeyEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME rock should turn == between generic vars into a memcmp itself
    memcmp(k1, k2, K size) == 0
}

/**
 * Port of Austin Appleby's Murmur Hash implementation
 * http://murmurhash.googlepages.com/
 * TODO: Use this to hash not just strings, but any type of object
 * @param key The key to hash
 * @param seed The seed value
 */
murmurHash: func <K> (keyTagazok: K) -> UInt {
    
    seed: UInt = 1 // TODO: figure out what makes a good seed value?
    
    len := K size
    m = 0x5bd1e995 : const UInt
    r = 24 : const Int
    l := len

    h : UInt = seed ^ len
    data := (keyTagazok&) as Octet*
    
    while (len >= 4) {
        k := (data as UInt*)@

        k *= m
        k ^= k >> r
        k *= m

        h *= m
        h ^= k

        data += 4
        len -= 4
    }

    t := 0

    /*
    match(len) {
        case 3 => h ^= data[2] << 16
        case 2 => h ^= data[1] << 8
        case 1 => h ^= data[0]
    }
    */
    
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
ac_X31_hash: func <K> (key: K) -> UInt {
    s := key as Char*
    h = s@ : UInt
    if (h) {
        s += 1
        while (s@) {
            h = (h << 5) - h + s@
            s += 1
        }
    }
    return h
}

/**
 * Simple hash table implementation
 */

HashMap: class <K, V> extends Iterable<V> {

    size, capacity: UInt
    keyEquals: Func <K> (K, K) -> Bool
    hashKey: Func <K> (K) -> UInt

    buckets: ArrayList<V>*
    keys: ArrayList<K>
    
    /**
     * Returns a hash table with 100 buckets
     * @return HashTable
     */
    
    init: func {
        init(100)
    }

    /**
     * Returns a hash table of a specified bucket capacity.
     * @param UInt capacity The number of buckets to use
     * @return HashTable
     */
    init: func ~withCapacity (=capacity) {
        size = 0
        buckets = gc_malloc(capacity * Pointer size)
        if (!buckets) {
            Exception new(This,
            "Out of memory: failed to allocate " + (capacity * Pointer size) + " bytes\n") throw()
        }
        for (i: UInt in 0..capacity) {
            buckets[i] = ArrayList<V> new()
        }
        keys = ArrayList<K> new()
        
        // choose comparing function for key type
        if(K == String) {
            keyEquals = stringKeyEquals
            hashKey = ac_X31_hash
        } else {
            keyEquals = genericKeyEquals
            hashKey = murmurHash
        }
    }

    /**
     * Returns the HashEntry associated with a key.
     * @access private
     * @param key The key associated with the HashEntry
     * @return HashEntry
     */
    getEntry: func (key: K) -> HashEntry<K, V> {
        entry = null : HashEntry<K, V>
        hash : UInt = hashKey(key) % capacity
        iter := buckets[hash] iterator()
        while (iter hasNext()) {
            entry = iter next()
            if(keyEquals(entry key, key)) {
                return entry
            }
        }
        return null
    }

    /**
     * Puts a key/value pair in the hash table. If the pair already exists,
     * it is overwritten.
     * @param key The key to be hashed
     * @param value The value associated with the key
     * @return Bool
     */
    put: func (key: K, value: V) -> Bool {
        load: Float
        hash: UInt
        entry := getEntry(key)
        if (entry) {
            entry value = value
        }
        else {
            keys add(key)
            hash = hashKey(key) % capacity
            entry = HashEntry<K, V> new(key, value)
            buckets[hash] add(entry)
            size += 1
            load = size / capacity as Float
            // was >= 0.8, * 2
            if (load > 0.7) {
                v1 = capacity / 0.7, v2 = capacity * 2 : Int
                resize(v1 > v2 ? v1 : v2)
            }
        }
        return true
    }

    /**
     * Alias of put
     */
    add: func (key: K, value: V) -> Bool {
        return put(key, value)
    }

    /**
     * Returns the value associated with the key. Returns null if the key
     * does not exist.
     * @param key The key associated with the value
     * @return Object
     */
    get: func (key: K) -> V {
        entry := getEntry(key)
        if (entry) {
	    return entry value
        }
        return null
    }

    /**
     * @return true if this map is empty, false if not
     */
    isEmpty: func -> Bool { keys isEmpty() }

    /**
     * Returns whether or not the key exists in the hash table.
     * @param key The key to check
     * @return Bool
     */
    contains: func (key: K) -> Bool {
        getEntry(key) ? true : false
    }

    /**
     * Removes the entry associated with the key
     * @param key The key to remove
     * @return Bool
     */
    remove: func (key: K) -> Bool {
        entry := getEntry(key)
        hash : UInt = hashKey(key) % capacity
        if (entry) {
            for (i: UInt in 0.. keys size()) {
                cKey := keys get(i)
                if(keyEquals(key, cKey)) {
                    keys removeAt(i)
                    break
                }
            }
            size -= 1
            return buckets[hash] remove(entry)
        }
        return false
    }

    /**
     * Resizes the hash table to a new capacity
     * @param UInt _capacity The new table capacity
     * @return Bool
     */
    resize: func (_capacity: UInt) -> Bool {
        
        /* Keep track of old settings */
        old_capacity := capacity
        old_buckets := gc_malloc(old_capacity * Pointer size) as ArrayList<V>*
        if (!old_buckets) {
            Exception new(This, "Out of memory: failed to allocate %d bytes\n" + (old_capacity * Pointer size)) throw()
        }
        for (i: UInt in 0..old_capacity) {
            old_buckets[i] = buckets[i] clone()
        }
        
        /* Clear key list */
        keys clear()
        
        /* Transfer old buckets to new buckets! */
        capacity = _capacity
        buckets = gc_malloc(capacity * Pointer size)
        if (!buckets) {
            Exception new(This, "Out of memory: failed to allocate %d bytes\n" + (capacity * Pointer size)) throw()
        }
        for (i: UInt in 0..capacity) {
            buckets[i] = ArrayList<V> new()
        }
        entry : HashEntry<K, V>
        for (bucket: UInt in 0..old_capacity) {
            if (old_buckets[bucket] size() > 0) {
                iter := old_buckets[bucket] iterator()
                while (iter hasNext()) {
                    entry = iter next()
                    put(entry key, entry value)
                }
            }
        }
        
        return true
    }
    
    iterator: func -> Iterator<V> {
        HashMapValueIterator<K, V> new(this)
    }

    clear: func {
        init(capacity)
    }
    
    size: func -> UInt { size }
    
    getKeys: func -> ArrayList<K> { keys }

}

HashMapValueIterator: class <K, T> extends Iterator<T> {

    map: HashMap<K, T>
    index := 0
    
    init: func ~withMap (=map) {}
    
    hasNext: func -> Bool { index < map keys size() }
    
    next: func -> T {
        key := map keys get(index)
        index += 1
        return map get(key)
    }
    
    hasPrev: func -> Bool { index > 0 }
    
    prev: func -> T {
        index -= 1
        key := map keys get(index)
        return map get(key)
    }
    
    remove: func -> Bool {
        result := map remove(map keys get(index))
        if(index <= map keys size()) index -= 1
        return result
    }
    
}

operator [] <K, V> (map: HashMap<K, V>, key: K) -> V {
    map get(key)
}

operator []= <K, V> (map: HashMap<K, V>, key: K, value: V) {
    map put(key, value)
}
