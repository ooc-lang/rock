Dog: class {
    
    name: String
    
    setName: func (name: String) {
        this name = name
    }
    
}

main: func {
    
    d : Dog
    //d = gc_malloc(Dog size)
    d class = Dog
    
    d setName("Fido")
    (d name) println()
    
    0
    
}