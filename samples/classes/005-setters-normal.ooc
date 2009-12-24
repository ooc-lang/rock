Dog: class {
    
    name: String
    
    setName: func (num: String) {
        this name = num
    }
    
}

main: func {
    
    d : Dog
    d = gc_malloc(Dog size)
    d class = Dog
    
    d setName("Fido")
    (d name) println()
    
    0
    
}
