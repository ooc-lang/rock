
AnthroPC: class <T> {
    
    init: func (.T) {
        this T = T
        printf("Just created %s<%s>\n", this as Object class name, T name)
    }
    
    doThing: func -> T { 42 }
    
}

main: func -> Int {
    
    a : AnthroPC<Int> = AnthroPC new(Int)
    i := a doThing()
    i toString() println()
    
    return 0
    
}
