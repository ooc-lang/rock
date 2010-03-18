import ArrayList

/**
 * Container for key/value entries in the hash table
 */
HashEntry: class <T> {

    key: String
    value: T

    init: func (=key, =value) {}

}

/**
 * Simple hash table implementation
 */

HashMap: class <T> extends Iterable<T> {

    size, capacity: UInt

    buckets: ArrayList<T>*
    keys: ArrayList<String>
    
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
            buckets[i] = ArrayList<T> new()
        }
        keys = ArrayList<String> new()
    }

    /**
     * Port of Austin Appleby's Murmur Hash implementation
     * http://murmurhash.googlepages.com/
     * TODO: Use this to hash not just strings, but any type of object
     * @param Object key The key to hash
     * @param Int len The size of the key (in bytes)
     * @param UInt seed The seed value
     */
    murmurHash: func (keyTagazok: T, seed: UInt) -> UInt {
        
        len := T size
        m = 0x5bd1e995 : const UInt
        r = 24 : const Int

        h : UInt = seed ^ len
        data := const keyTagazok as Octet*

        while (len >= 4) {
            k := (data as UInt*) @

            k *= m
            k ^= k >> r
            k *= m

            h *= m
            h ^= k

            data += 4
            len -= 4
        }

        if(len == 3) h ^= data[2] << 16
        if(len == 2) h ^= data[1] << 8
        if(len == 1) h ^= data[0]
        else         h *= m    
                
        h ^= h >> 13
        h *= m
        h ^= h >> 15

        return h
    }

    /**
     * khash's ac_X31_hash_string
     * http://attractivechaos.awardspace.com/khash.h.html
     * @access private
     * @param String s The string to hash
     * @return UInt
     */
    ac_X31_hash: func (s: Char*) -> UInt {
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
     * Returns the HashEntry associated with a key.
     * @access private
     * @param String key The key associated with the HashEntry
     * @return HashEntry
     */
    getEntry: func (key: String) -> HashEntry<T> {
        entry = null : HashEntry<T>
        hash : UInt = ac_X31_hash(key) % capacity
        iter := buckets[hash] iterator()
        while (iter hasNext()) {
            entry = iter next()
            if (entry key equals(key)) {
                return entry
            }
        }
        return null
    }

    /**
     * Puts a key/value pair in the hash table. If the pair already exists,
     * it is overwritten.
     * @param String key The key to be hashed
     * @param Object value The value associated with the key
     * @return Bool
     */
    put: func (key: String, value: T) -> Bool {
        load: Float
        hash: UInt
        entry := getEntry(key)
        if (entry) {
            entry value = value
        }
        else {
            keys add(key)
            hash = ac_X31_hash(key) % capacity
            entry = HashEntry<T> new(key, value)
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
    add: func (key: String, value: T) -> Bool {
        return put(key, value)
    }

    /**
     * Returns the value associated with the key. Returns null if the key
     * does not exist.
     * @param String key The key associated with the value
     * @return Object
     */
    get: func (key: String) -> T {
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
     * @param String key The key to check
     * @return Bool
     */
    contains: func (key: String) -> Bool {
        getEntry(key) ? true : false
    }

    /**
     * Removes the entry associated with the key
     * @param String key The key to remove
     * @return Bool
     */
    remove: func (key: String) -> Bool {
        entry := getEntry(key)
        hash : UInt = ac_X31_hash(key) % capacity
        if (entry) {
            for (i: UInt in 0.. keys size()) {
                cKey := keys get(i)
                if (key equals(cKey)) {
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
        old_buckets := gc_malloc(old_capacity * Pointer size) as ArrayList<T>*
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
            buckets[i] = ArrayList<T> new()
        }
        entry : HashEntry<T>
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
    
    iterator: func -> Iterator<T> {
        HashMapValueIterator<T> new(this)
    }

    clear: func {
        init(capacity)
    }
    
    size: func -> UInt { size }
    
    getKeys: func -> ArrayList<String> { keys }

}

HashMapValueIterator: class <T> extends Iterator<T> {

    map: HashMap<T>
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

operator [] <T> (map: HashMap<T>, key: String) -> T {
    map get(key)
}

operator []= <T> (map: HashMap<T>, key: String, value: T) {
    map put(key, value)
}
