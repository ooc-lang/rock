import structs/LinkedList

Cacou: class {
    idSeed = 0: static Int
    id: Int
    
    init: func {
        id = idSeed
        idSeed += 4
    }
    
    draw: func {
        printf("Drawing kakoo %d\n", id)
    }
}

main: func {
    list := LinkedList<Cacou> new()
    for(i in 1..10) {
        list add(Cacou new())
    }
    
    for(kakoo in list) {
        kakoo draw()
    }
}
