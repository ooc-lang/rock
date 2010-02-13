Array: class <T> extends Iterable<T> {

	size: SizeT
	data: T*
	
	init: func ~withSize (=size) {
		data = gc_calloc(size, T size)
	}

    // FIXME .data should work!
	init: func ~withData (data: Pointer, =size) {
		this data = gc_calloc(size, T size)
		memcpy(this data, data, size * T size)
	}
	
	get: func (i: Int) -> T {
		if(i < 0 || i >= size) {
			Exception new(This, "Attempting to access an array of size " append(
				size as Int toString()) append(" at index ") append(i toString()) append("\n")) throw()
		}
		return data[i]
	}
	
	set: func (i : Int, value: T) {
		if(i < 0 || i >= size) {
			Exception new(This, "Attempting to set the value of an array of size " append(
				size as Int toString()) append(" at index ") append(i toString()) append("\n")) throw()
		}
		data[i] = value
	}
	
	size: func -> Int {
		return size
	}

	/*
	nullTerminated: static func (p : T*) -> Array {
		Object* q = p;
		while(*q) q++;
		return new Array(q - p, p);
	}
	*/
	
    /*
	iterator: func -> Iterator<T> {
		return ArrayIterator<T> new(this)
	}

	lastIndex: func -> SizeT {
		return size - 1
	}
	
	isEmpty: func -> Bool {
		return size == 0
	}
	
	each: func (f: Func (T)) {
		for(i in 0..size) {
			f(get(i))
		}
	}
    */

}

ArrayIterator: class <T> extends Iterator {
	
	array: Array<T>
	i := 0
	
	init: func ~array (=array) {}
	
	hasNext: func -> Bool { i < array size }
	
	next: func -> T {
		value := array get(i)
		i += 1
		return value
	}
    
    hasPrev: func -> Bool { i > 0 }
    
    prev: func -> T {
        i -= 1
        value := array get(i)
        return value
    }
    
    remove: func -> Bool { false }
	
}

operator [] <T> (arr: Array<T>, index: Int) -> T {
	return arr get(index)
}

operator []= <T> (arr: Array<T>, index: Int, value: T) {
	arr set(index, value)
}

