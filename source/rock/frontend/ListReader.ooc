import structs/List

ListReader: class <T> {

    list: List<T>
    index, length, mark : SizeT

    init: func (=list) {
        index = 0
        length = list size()
        mark = 0
    }
    
    hasNext: func -> Bool {
        index < length
    }
    
    read: func -> T {
        val := list get(index)
        index += 1
        return val
    }
    
    peek: func -> T {
        if(index >= list size()) return null
        val := list get(index)
        return val
    }
    
    prev: func -> T {
        if(index < 1) return list get(index)
        return list get(index - 1)
    }
    
    mark: func -> SizeT {
        mark = index
        return mark
    }
    
    reset: func {
        index = mark
    }
    
    seek: func (.index) {
        this index = index
    }
    
    rewind: func  {
        index -= 1
    }
    
    skip: func {
        index += 1
    }
    
    skip: func ~withOffset (offset: SizeT) {
        index += offset
    }
    
}
