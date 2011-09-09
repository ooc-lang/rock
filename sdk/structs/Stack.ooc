import structs/ArrayList

Stack: class <T> extends BackIterable<T> {
    data: ArrayList<T>
    
    size: SSizeT {
        get {
            data != null ? data size : 0		
        }
    }
    
    init: func {
        data = ArrayList<T> new()
    }

    push: func(element: T) {
        data add(element)
    }
    
    pop: func -> T {
        if (empty?())
            Exception new(This, "Trying to pop an empty stack.") throw()
            
        return data removeAt(lastIndex())
    }
    
    peek: func -> T {
        if (empty?())
            Exception new(This, "Trying to peek an empty stack.") throw()
                
        return data last()
    }

    peek: func ~index (index: SSizeT) -> T {
        mysize := data size
        if (index < 1)
            Exception new(This, "Trying to peek(%d)! index must be >= 1 <= size" format(index)) throw()

        if (index > mysize)
            Exception new(This, "Trying to peek(%d) a stack of size %d" format(index, mysize)) throw()

        return data get(mysize - index)
    }

    indexOf: func(element: T) -> SSizeT {
        return data indexOf(element)
    }
	
    getSize: func -> SSizeT {	
        return data size
    }
    
    empty?: func -> Bool {
        return data empty?()
    }
    
    lastIndex: func -> Int {
        return size - 1
    }

    clear: func {
        data clear()
    }

    iterator: func -> BackIterator<T> { data iterator() }

    backIterator: func -> BackIterator<T> { data backIterator() }
}
