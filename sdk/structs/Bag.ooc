import structs/[ArrayList,List,HashBag]

Bag: class {

    // NOTE: most "real" code taken from sdk/structs/ArrayList
    data: ArrayList<Cell<Pointer>>
    
    size: SSizeT {
    	get {
    		data size
    	}
    }

    init: func ~withCapacity(len: SizeT) {
        data = ArrayList<Cell<Pointer>> new(len)
    }

    init: func {
        init ~withCapacity(10)
    }

    add: func <T> (element: T) {
        data add(Cell<T> new(element))
    }

    add: func ~withIndex <T> (index: SSizeT, element: T) {
        data add(index, Cell<T> new(element))
    }

    clear: func { data clear() }

    get: func <T> (index: SSizeT, T: Class) -> T {
        data get(index) val // yolo
    }

    indexOf: func <T> (element: T) -> SSizeT {
        index := -1
        while (index < data size) {
            index += 1
            candidate: T
            candidate = data get(index) val
            if(memcmp(candidate&, element&, T size) == 0) return index
        }
        return -1
    }

    lastIndexOf: func <T> (element: T) -> SSizeT {
        index := data size
		while(index) {
			candidate: T
			candidate = data[index] val
            // that workaround sucks, but it works
			if(memcmp(candidate&, element&, T size) == 0) return index
			index -= 1
		}
		return -1
    }

    removeAt: func <T> (index: SSizeT, T: Class) -> T {
        tmp := data removeAt(index)
        return tmp val 
    }

    remove: func <T> (element: T) -> Bool {
        tmp := Cell<T> new(element)
        data remove(tmp)
    }

    set: func <T> (index: SSizeT, element: T) {
        tmp := Cell<T> new(element)
        data set(index, tmp)
    }

    getSize: func -> SSizeT {data size}

    getClass: func (index: SSizeT) -> Class {
        data get(index) T
    }

    /**
     * Converts this bag to a variable argument list
     */
    toVarArgs: func -> VarArgs {
        va: VarArgs
        
        bytesCount := 0
        for(cell in data) bytesCount += __pointer_align(cell T size)
        
        va init(size, bytesCount)
        for(cell in data) {
            T := cell T
            val: T = cell val
            va _addValue(val)
        }
        va
    }

    /** Get a value out of nested bags/hashbags. See `structs/HashBag getPath`. */
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
                bag := get(currentKey toString() toInt(), Bag)
                return bag getPath(path substring(index + 1), T)
            } else if(chr == '/') {
                // a hashbag.
                hashBag := get(currentKey toString() toInt(), HashBag)
                return hashBag getPath(path substring(index + 1), T)
            } else {
                // oh, nothing special, just add it
                currentKey append(chr)
            }
            index += 1
        }
        // No subpaths, just return the value.
        get(currentKey toString() toInt(), T)
    }
}

operator as <T> (array : T[]) -> Bag {
    array as ArrayList<T> as Bag
}

operator as <T> (list : List<T>) -> Bag {
    bag := Bag new(list getSize())

    for (item: T in list) {
        bag add(item)
    }
    bag
}

// Add the toBag() method to VarArgs - this belongs here because Bag
// is defined here and because we don't want to pull in structs/Bag
// because of lang/VarArgs
extend VarArgs {

    toBag: func -> Bag {
        bag := Bag new(count)
        each(|arg|
            bag add(arg)
        )
        bag
    }

}


