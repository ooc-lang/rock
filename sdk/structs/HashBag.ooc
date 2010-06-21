import structs/HashMap

HashBag: class {

    myMap: HashMap<String, Cell<Pointer>>
    
    init: func {
        init ~withCapacity(10)
    }

    init: func ~withCapacity(capacity: Int) {
        myMap = HashMap<String, Cell<Pointer>> new(capacity)
    }

    get: func <T> (key: String, T: Class) -> T {
        return getEntry(key, T) value as T
    }

    getEntry: func <V> (key: String, V: Class) -> HashEntry<String, Pointer> {
        entry: HashEntry<String, Cell<V>>
        if(myMap getEntry(key, entry&)) {
            cell := entry value as Cell<V>
            return HashEntry<String, V> new(key, cell val)
        } else {
            return HashEntry<String, V> new(key, None new())
        }
    }

    put: func <T> (key: String, value: T) -> Bool {
        tmp := Cell<T> new(value)
        return myMap put(key, tmp)
    }

    add: func <T> (key: String, value: T) -> Bool {
        return put(key, value)
    }

    isEmpty: func -> Bool {return myMap isEmpty()}
    
    remove: func (key: String) -> Bool {
        return myMap remove(key)
    }
    
    size: func -> Int {myMap size}
    
    contains: func(key: String) -> Bool {
        myMap get(key) ? true : false
    }
}

