MyArray: class <T> {

    data: T*
    size: SizeT

    init: func (=size) {
        data = gc_malloc(T size * size)
    }
        
    get: func (index: SizeT) -> T {
        return data[index]
    }

    set: func (index: SizeT, element: T) {
        data[index] = element
    }

}

main: func {

    max := 10
    println("Creating an array of ints")
    arr := MyArray<Int> new(max)
    
    for (i in 0..max) {
        arr set(i, max - i);
    }
    
    printf("Array's content = ")
    isFirst := true
    for (i in 0..max) {
        if(!isFirst) printf(", ")
        isFirst = false
        printf("%d", arr get(i))
    }
    println()
    
    println("Creating an array of chars")
    chars := MyArray<Char> new(max)
    
    max = 26
    for (i in 0..max) {
        chars set(i, ('a' as Int + i) as Char);
    }
    
    printf("Chars's content = ")
    isFirst = true
    for (i in 0..max) {
        if(!isFirst) printf(", ")
        isFirst = false
        printf("%c", chars get(i))
    }
    println()
    
}
