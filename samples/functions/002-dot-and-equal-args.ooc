Dog: class {
    
    name: String
    age: Int
    
    init: func {}
    
    setName: func (.name) {
        this name = name
    }
    
    setAge: func (=age) {}
    
}

main: func {
    
    dog := Dog new()
    dog setName("Dogbert")
    dog setAge(91)
    printf("dog name = %s, dog age = %d\n", dog name, dog age)
    
}

