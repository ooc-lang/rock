import MultiMap, ArrayList

OrderedMultiMap: class <T> extends MultiMap<T> {
    
    orderedKeys := ArrayList<String> new()
    
    // MultiMapValueIterator uses getKeys(), so it will iterate in order =)
    getKeys: func -> ArrayList<String> { orderedKeys }
    
    _containsKey: func (key: String) -> Bool {
        result := false
        for(candidate in orderedKeys) {
            if(candidate equals(key)) {
                result = true; break
            }
        }
        return result
    }
    
    put: func (key: String, value: T) -> Bool {
        // in a MultiMap, the same key can have several values
        // we only add the key to the list if there's no value for this key yet
        if(!_containsKey(key)) {
            orderedKeys add(key)
        }
        return super put(key clone(), value)
    }
    
    remove: func (key: String) -> Bool {
        super remove(key)
        // in a MultiMap, the same key can have several values
        // we only remove the key from the list if there are no values left
        if(!contains(key)) {
            orderedKeys remove(key)
        }
        return true
    }
    
}