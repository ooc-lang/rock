import HashMap, ArrayList, List

/**
 * A MultiMap allows a mapping from one key to several values
 */
MultiMap: class <K, V> extends HashMap<K, V> {

    init: func ~multiMap {
        init(10)
    }
    
    init: func ~multiMapWithCapa(.capacity) {
        if(!V inheritsFrom(Object)) {
            Exception new(This, "Can't create multimaps of %s, V must inherit from object." format(V name)) throw()
        }
        super(capacity)
    }
    
    get: func ~_super (key: K) -> K {
        super(key)
    }
    
    put: func ~_super (key: K, value: V) -> Bool {
        super(key, value)
    }
    
    put: func (key: K, value: V) -> Bool {
        already := get~_super(key) as Object
        if(already == null) {
            // First of the kind - just put it
            put~_super(key, value)
        } else if(already instanceOf(List)) {
            // Already at least two - append to the list
            list := already as List<V>
            list add(value)
        } else {
            // Second of the kind - create a list
            list := ArrayList<V> new()
            list add(already)
            list add(value)
            put~_super(key, list)
        }
        return true
    }
    
    remove: func (key: K) -> Bool {
        already := get~_super(key) as Object
        if(already == null) {
            // Doesn't contain it
            return false
        } else if (already instanceOf(List)) {
            // Already at least two - remove from the list, from last to first
            list := already as List<V>
            list removeAt(list lastIndex())
            if(list size() == 1) {
                // Only one left - turn the list into a single element
                put~_super(key, list first())
            }
        } else {
            // Only one - remove it
            return super(key)
        }
    }
    
    getAll: func (key: K) -> V {
        get~_super(key)
    }
    
    get: func (key: K) -> V {
        val := super(key) as Object
        if(val == null) {
            return val
        } else if(val instanceOf(List)) {
            list := val as List<V>
            return list last()
        }
        return val
    }
    
    iterator: func -> Iterator<V> {
        MultiMapValueIterator<K, V> new(this)
    }

}

MultiMapValueIterator: class <K, V> extends Iterator<V> {

    map: MultiMap<K, V>
    index := 0
    sub : Iterator<V>
    
    init: func(=map) {}
    
    hasNext: func -> Bool { index < map getKeys() size() && (sub == null || sub hasNext()) }
    
    next: func -> V {

        // not in list mode
        if(!sub) {
            // retrieve value
            key := map getKeys() get(index)
            val := map getAll(key) as Object
            if(val instanceOf(List)) {
                // switch in list mode
                sub = val as List<V> iterator()
            } else {
                // no list - go to next element and return
                index += 1
                return val
            }
        }
        
        // in list mode
        if(sub) {
            val := sub next()
            if(!sub hasNext()) {
                // end of the list? switch back in single mode
                index += 1
                sub = null
            }
            return val
        }
        
        return null
    }
    
    /* TODO: stub */
    
    hasPrev: func -> Bool { false }
    
    prev: func -> V {
        null
    }
    
    remove: func -> Bool {
        return false
    }
    
}

operator [] <K, V> (map: MultiMap<K, V>, key: K) -> V {
    map get(key)
}

operator []= <K, V> (map: MultiMap<K, V>, key: K, value: V) {
    map put(key, value)
}
