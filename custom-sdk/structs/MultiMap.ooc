import HashMap, ArrayList, List

/**
 * A MultiMap allows a mapping from one key to several values
 */
MultiMap: class <T> extends HashMap<T> {

    init: func ~multiMap {
        super()
        if(!T inheritsFrom(Object)) {
            Exception new(This, "Can't create multimaps of %s, which doesn't inherit from Object" format(T name)) throw()
        }
    }
    
    put: func (key: String, value: T) -> Bool {
        already := super get(key) as Object
        if(already == null) {
            // First of the kind - just put it
            super put(key, value)
        } else if(already instanceOf(List)) {
            // Already at least two - append to the list
            list := already as List<T>
            list add(value)
        } else {
            // Second of the kind - create a list
            list := ArrayList<T> new()
            list add(already)
            list add(value)
            super put(key, list)
        }
        
        return true
    }
    
    remove: func (key: String) -> Bool {
        already := super get(key) as Object
        if(already == null) {
            // Doesn't contain it
            return false
        } else if (already instanceOf(List)) {
            // Already at least two - remove from the list, from last to first
            list := already as List<T>
            list removeAt(list lastIndex())
            if(list size() == 1) {
                // Only one left - turn the list into a single element
                super put(key, list first())
            }
        } else {
            // Only one - remove it
            return super remove(key)
        }
        // work-around
        return false
    }
    
    getAll: func (key: String) -> T {
        super get(key)
    }
    
    get: func (key: String) -> T {
        val := super get(key) as Object
        if(val == null) {
            return val
        } else if(val instanceOf(List)) {
            list := val as List<T>
            return list last()
        }
        return val
    }
    
    iterator: func -> Iterator<T> {
        MultiMapValueIterator<T> new(this)
    }

}

MultiMapValueIterator: class <T> extends Iterator<T> {

    map: MultiMap<T>
    index := 0
    sub : Iterator<T>
    
    init: func(=map) {}
    
    hasNext: func -> Bool { index < map getKeys() size() && (sub == null || sub hasNext()) }
    
    next: func -> T {

        // not in list mode
        if(!sub) {
            // retrieve value
            key := map getKeys() get(index)
            val := map getAll(key) as Object
            if(val instanceOf(List)) {
                // switch in list mode
                sub = val as List<T> iterator()
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
    
    prev: func -> T {
        null
    }
    
    remove: func -> Bool {
        return false
    }
    
}

operator [] <T> (map: MultiMap<T>, key: String) -> T {
    map get(key)
}

operator []= <T> (map: MultiMap<T>, key: String, value: T) {
    map put(key, value)
}
