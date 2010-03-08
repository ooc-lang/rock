import structs/ArrayList

main: func {
    
    list := [1, 2, 3, 4]
    elem3 := fiddleDum(list)
    printf("list[3] = %d\n", elem3)
    
}

fiddleDum: func <T> (list: ArrayList<T>) -> Int {
    
    "Got a list of %s" format(T name) println()
    
    elem0 := list get(0) as Int
    printf("list[0] = %d\n", elem0)
    
    elem1 : Int
    elem1 = list get(1) as Int
    printf("list[1] = %d\n", elem1)
    
    elem2 : Int = list get(2)
    printf("list[2] = %d\n", elem2)
    
    return list get(3) as Int
    
}
