import structs/List

RangeList: class extends List<T> {
    
    data : List<T>
    range: Range
    
    init: func (=data, =range) {}
    
    iterator: func -> Iterator<T> { RangeListIterator<T> new(this) }
    
}

RangeListIterator: class extends BackIterator<T> {

    list: RangeList<T>
    remaining : Int
    subIter : Iterator<T>
    
    init: func(=list) {
        subIter := list data iter()
        for(i in 0..list range min) {
            subIter next()
        }
        remaining = list range max - list range min
    }
    
    next: func -> T {
        remaining -= 1
        return subIter next()
    }
    
    hasNext: func -> Bool {
        remaining > 0
    }
    
    /* TODO: stub */
    
    prev: func -> T { null }
    
    hasPrev: func -> Bool { false }
    
    remove: func -> Bool { false }
    
}