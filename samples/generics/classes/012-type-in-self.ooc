
Container: class <T> {
    
    removeAt: func (index: Int) -> T {
        printf("Removing %s #%d\n", T name, index); null
    }
    
    doThing: func {
        a := removeAt(42)
    }
    
}

main: func {
    Container<Int> new() doThing()
}