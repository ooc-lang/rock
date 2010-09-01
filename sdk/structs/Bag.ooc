import structs/[ArrayList,List]

Bag: class {

    // NOTE: most "real" code taken from sdk/structs/ArrayList
    data: ArrayList<Cell<Pointer>>
    
    size: SizeT {
    	get {
    		data getSize()
    	}
    }

    init: func ~withCapacity(len: SizeT) {
        data = ArrayList<Cell<Pointer>> new(len)
    }

    init: func {
        init ~withCapacity(10)
    }

    add: func <T> (element: T) {
        tmp := Cell<T> new(element)
        data add(tmp)
    }

    add: func ~withIndex <T> (index: SSizeT, element: T) {
        tmp := Cell<T> new(element)
        data add(index, tmp)
    }

    clear: func {data clear()}

    get: func <T> (index: SSizeT, T: Class) -> T {
        tmp := data get(index)
        return tmp val
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

    getSize: func -> SizeT {data size}

    getClass: func (index: SSizeT) -> Class {
        data get(index) T
    }
}

operator as <T> (array : T[]) -> Bag {
    array as ArrayList<T> as Bag
}

operator as <T> (list : List<T>) -> Bag {
    bag := Bag new(list getSize())

    for (item : T in list)
    {
        bag add(item)
    }

    bag
}
