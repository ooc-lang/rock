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

nullHashEntry: HashEntry <None, None>
memset(nullHashEntry&, 0, HashEntry size)

stringKeyEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME those casts shouldn't be needed,
    // and this method doesn't belong here
    k1 as String equals(k2 as String)
}

intKeyEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME those casts shouldn't be needed,
    // and this method doesn't belong here
    k1 as Int == k2 as Int
}

charKeyEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME those casts shouldn't be needed,
    // and this method doesn't belong here
    k1 as Char == k2 as Char
}

/** used when we don't have a custom comparing function for the key type */
genericKeyEquals: func <K> (k1, k2: K) -> Bool {
    // FIXME rock should turn == between generic vars into a memcmp itself
    memcmp(k1, k2, K size) == 0
}

intHash: func <K> (key: K) -> UInt {
    return key as UInt
}

charHash: func <K> (key: K) -> UInt {
    // both casts are necessary
    // Casting 'key' directly to UInt would deref a pointer to UInt
    // which would read random memory just after the char, which is not a good idea..
    return (key as Char) as UInt
}

/**
   Port of Austin Appleby's Murmur Hash implementation
   http://murmurhash.googlepages.com/
   
   :param: key The key to hash
   :param: seed The seed value
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

HashMap: class <K, V> extends BackIterable<V> {

    size, capacity: Int
    keyEquals: Func <K> (K, K) -> Bool
    hashKey: Func <K> (K) -> UInt

    buckets: HashEntry[]
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
    init: func ~withCapacity (capaArg: Int) {
        size = 0
        capacity = capaArg * 1.5
        
        buckets = HashEntry[capacity] new()
        
        keys = ArrayList<K> new(capacity)
        
        // choose comparing function for key type
        if(K == String) {
            //"Choosing string hashing function" println()
            keyEquals = stringKeyEquals
            hashKey = ac_X31_hash
        } else if(K size == UInt size) {
            //"Choosing int hashing function" println()
            keyEquals = intKeyEquals
            hashKey = intHash
        } else if(K size == Char size) {
            //"Choosing char hashing function" println()
            keyEquals = charKeyEquals
            hashKey = charHash
        } else {
            //"Choosing generic hashing function" println()
            keyEquals = genericKeyEquals
            hashKey = murmurHash
        }
    }

    /**
     * Returns the HashEntry associated with a key.
     * @param key The key associated with the HashEntry
     * @return HashEntry
     */
    getEntry: func (key: K, result: HashEntry*) -> Bool {
        hash : UInt = hashKey(key) % capacity
        
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
    getEntryForHash: func (key: K, hash: UInt, result: HashEntry*) -> Bool {
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

    /**
     * Puts a key/value pair in the hash table. If the pair already exists,
     * it is overwritten.
     * @param key The key to be hashed
     * @param value The value associated with the key
     * @return Bool
     */
    put: func (key: K, value: V) -> Bool {
        
        hash : UInt = hashKey(key) % capacity
        entry : HashEntry
        //printf("\nput(%s, value %p\n", key as String, value)
        
        if (getEntryForHash(key, hash, entry&)) {
            // replace value if the key is already existing
            //" - Replacing! Address = %p, size = %d" printfln(entry value, V size)
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
                //" - Adding normally!! HashEntry size = %d, Address of buckets data = %p" printfln(HashEntry size, buckets data)

                entry key   = gc_malloc(K size)
                memcpy(entry key,   key, K size)
                
                entry value = gc_malloc(V size)
                memcpy(entry value, value, V size)
                
                entry next = null
                
                //"     - entry key   = %p, size = %d, hash = %u" printfln(entry key, K size, hash)
                //"     - entry value = %p, size = %d, next = %p" printfln(entry value, V size, entry next)
                
                buckets[hash] = entry
            }
            size += 1
            
            if ((size as Float / capacity as Float) > 0.8) {
                v1 = capacity / 0.8, v2 = capacity * 2 : Int
                resize(v1 > v2 ? v1 : v2)
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

        //"\nget(%s" printfln(key as String)
        if (getEntry(key, entry&)) {
            return entry value as V
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
        getEntry(key, null)
    }

    /**
     * Removes the entry associated with the key
     * @param key The key to remove
     * @return Bool
     */
    remove: func (key: K) -> Bool {
        hash : UInt = hashKey(key) % capacity
        
        prev = null : HashEntry*
        
        entry := buckets[hash]
        if(entry key == null) return false
        
        while (true) {
            if (keyEquals(entry key as K, key)) {
                if(prev) {
                    // re-connect the previous to the next one
                    prev@ next = entry next
                } else {
                    // just put the next one instead of us
                    if(entry next) {
                        buckets[hash] = entry next@
                    } else {
                        buckets[hash] = nullHashEntry
                    }
                }
                for (i in 0..keys size()) {
                    cKey := keys get(i)
                    if(keyEquals(key, cKey)) {
                        keys removeAt(i)
                        break
                    }
                }
                size -= 1
                return true
            }
            
            // do we have a next element?
            if(entry next) {
                // save the previous just to know where to reconnect
                prev = entry&
                entry = entry next@
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
    resize: func (_capacity: Int) -> Bool {
        
        /* Keep track of old settings */
        oldCapacity := capacity
        oldBuckets := buckets
        
        /* Clear key list and size */
        keys clear()
        size = 0
        
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
        
        return true
    }
    
    iterator: func -> BackIterator<V> {
        HashMapValueIterator<K, V> new(this)
    }
    
    backIterator: func -> BackIterator<V> {
        iter := HashMapValueIterator<K, V> new(this)
        iter index = keys size()
        return iter
    }

    clear: func {
        init(capacity)
    }
    
    size: func -> Int { size }
    
    getKeys: func -> ArrayList<K> { keys }
    
    each: func (f: Func (K, V)) {
        for(key in getKeys()) {
            f(key, get(key))
        }
    }

}

HashMapValueIterator: class <K, T> extends BackIterator<T> {

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
