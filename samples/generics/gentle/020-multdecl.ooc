//import structs/ArrayList

Pair: class <T> {
    
    a,b : T
    init: func(=a, =b) {}
    
    getA: func -> T { a }
    getB: func -> T { b }
    
}

main: func {

    p1 : Pair<String> = Pair<String> new("Bonnnie", "Euclyde")
    //printf("(%s, %s)\n", p1 a as String, p1 b as String)
    //printf("(%s, %s)\n", p1 a, p1 b)
    printf("(%s, %s)\n", p1 getA(), p1 getB())
    
}

/*
operator as <T> (data: T*, size: SizeT) -> Pair<T> { Pair<T> new(data as String* [0], data as String* [1]) }

main: func {
    
    print := func (p: Pair<String>) { printf("(%s, %s)\n", p a, p b) }
    
    p1 := ["Bonnie", "Clyde"] as Pair
    p2 := ["Romeo", "Juliet"] as Pair
    
    for(i in 0..2) {
        print([p1, p2][i])
    }
    
}
*/