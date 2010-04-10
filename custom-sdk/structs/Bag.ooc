import structs/ArrayList

Bag: class {

    // NOTE: most "real" code taken from sdk/structs/ArrayList
    data: ArrayList<Cell<Pointer>>

    init: func ~withCapacity(len: Int) {
        data = ArrayList<Cell<Pointer>> new(len)
    }

    init: func {
        init ~withCapacity(10)
    }

    add: func <T> (element: T) {
        tmp := Cell<T> new(element)
        data add(tmp)
    }

    add: func <T> ~withIndex(index: Int, element: T) {
        tmp := Cell<T> new(element)
        data add(index, tmp)
    }

    clear: func {data clear()}

    get: func <T> (index: Int, T: Class) -> T {
        tmp := data get(index)
        return tmp val
    }

    indexOf: func <T> (element: T) -> Int {
        index := -1
        while (index < data size) {
            index += 1
            candidate: T
            candidate = data get(index) val
            if(memcmp(candidate&, element&, T size) == 0) return index
        }
        return -1
    }

    lastIndexOf: func <T> (element: T) -> Int {
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

    removeAt: func <T> (index: Int, T: Class) -> T {
        tmp := data removeAt(index)
        return tmp val 
    }

    remove: func <T> (element: T) -> Bool {
        tmp := Cell<T> new(element)
        data remove(tmp)
    }

    set: func <T> (index: Int, element: T) {
        tmp := Cell<T> new(element)
        data set(index, tmp)
    }

    size: func -> Int {data size}
}


