
AnthroPC: class <T> {
    
    init: func (=T) {
        printf("Just created %s<%s>\n", this as Object class name, T name)
    }
    
}

main: func {
    
    a : AnthroPC<Int> = AnthroPC new(Int)
    
    
}
