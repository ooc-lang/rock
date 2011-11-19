import structs/[ArrayList, HashMap, Bag]

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

    /** Return a value out of nested HashBags/Bags. XPath-like.
        Valid syntax:
            `blab/blub`
                Get the `blab` value, which is a HashBag, and get
                this hashbag's `blub` value.
            `blab#0`
                Get the `blab` value, which is a Bag, and get the first
                (0) element. 
    */
    getPath: func <T> (path: String, T: Class) -> T {
        // the current position in our path string
        index := 0
        // the path element currently being constructed
        currentKey := Buffer new()
        // now, parse until we hit the first `/` or `#`. Then,
        // just continue parsing recursively.
        while(index < path length()) {
            chr := path[index]
            if(chr == '#') {
                // a bag is requested. well, just do it recursively.
                bag := get(currentKey toString(), Bag)
                return bag getPath(path substring(index + 1), T)
            } else if(chr == '/') {
                // a hashbag.
                hashBag := get(currentKey toString(), HashBag)
                return hashBag getPath(path substring(index + 1), T)
            } else {
                // oh, nothing special, just add it
                currentKey append(chr)
            }
            index += 1
        }
        // No subpaths, just return the value.
        get(currentKey toString(), T)
    }
}

