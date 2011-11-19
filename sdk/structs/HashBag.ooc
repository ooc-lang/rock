import structs/[ArrayList, HashMap]

HashBag: class {

    myMap: HashMap<String, Cell>

    init: func {
        init ~withCapacity(10)
    }

    init: func ~withCapacity(capacity: Int) {
        myMap = HashMap<String, Cell<Pointer>> new(capacity)
    }

    /** Fetch the value. If it doesn't exist in the HashMap or the types don't
        match, throw an Exception. */
    get: func <T> (key: String, T: Class) -> T {
        if(!contains?(key)) {
            Exception new(This, "Invalid value: %s" format(key)) throw() // TODO: more specific exception
        } else {
            storedType := getClass(key)
            // is `T` a derived type or the same type as the stored type?
            if(T inheritsFrom?(storedType)) {
                return getEntry(key, T) value as T
            } else {
                Exception new(This, "Invalid type: %s (stored: %s)" format(T name, storedType name)) throw() // TODO: more specific exception
            }
        }
    }

    getClass: func (key: String) -> Class {
        return myMap get(key) as Cell T
    }

    getEntry: func <V> (key: String, V: Class) -> HashEntry<String, Pointer> {
        entry: HashEntry
        if(myMap getEntry(key, entry&)) {
            cell := (entry value as Cell<V>*)@ as Cell<V>
            return HashEntry<String, V> new(key, cell val&)
        } else {
            none := None new()
            return HashEntry<String, V> new(key, none&)
        }
    }

    put: func <T> (key: String, value: T) -> Bool {
        tmp := Cell<T> new(value)
        return myMap put(key, tmp)
    }

    add: func <T> (key: String, value: T) -> Bool {
        return put(key, value)
    }

    empty?: func -> Bool {return myMap empty?()}

    remove: func (key: String) -> Bool {
        return myMap remove(key)
    }

    size: func -> Int {myMap size}

    contains?: func(key: String) -> Bool {
        myMap contains?(key)
    }

    getKeys: func -> ArrayList<String> {
        myMap getKeys()
    }
}

