import structs/[LinkedList, ArrayList]

MyNode: class <T> {
    
    data: T
    init: func(=data) {}
    
}

Container: class<T> {
    
    //list := LinkedList<Node<T>> new()
    list := ArrayList<Node<T>> new()
    
    add: func (val: T) {
        list add(MyNode<T> new(val))
    }
    
    get: func (index: Int) -> Node<T> {
        list get(index)
    }
    
    size: func -> SizeT { list size() }
    
}

main: func {
    list := Container<Int> new()
    for(i in 1..10) {
        list add(42)
    }
    
    for(i in 0..list size()) {
        node := list get(i)
        printf("Got a %s<%s>\n", node class name, node T name)
        //kakoo := node data
        //kakoo draw()
    }
}
