import MultiMap, HashMap, ArrayList

OrderedMultiMap: class <K, V> extends MultiMap<K, V> {
    
    orderedKeys := ArrayList<K> new()
    
    // MultiMapValueIterator uses getKeys(), so it will iterate in order =)
    getKeys: func -> ArrayList<K> { orderedKeys }
    
    _containsKey: func (key: K) -> Bool {
        result := false
        for(candidate in orderedKeys) {
            if((this as HashMap<K, V>) keyEquals(candidate, key)) {
                result = true; break
            }
        }
        return result
    }
    
    put: func (key: K, value: V) -> Bool {
        // in a MultiMap, the same key can have several values
        // we only add the key to the list if there's no value for this key yet
        if(!_containsKey(key)) {
            orderedKeys add(key)
        }
        return super(key, value)
    }
    
    remove: func (key: K) -> Bool {
        super(key)
        // in a MultiMap, the same key can have several values
        // we only remove the key from the list if there are no values left
        if(!contains(key)) {
            orderedKeys remove(key)
        }
        return true
    }
    
}