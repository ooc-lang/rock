Dog: class {
    
    name: String
    age: Int
    
    init: func {
        name = "Fido"
        age = 5
    }
    
}

main: func {
    
    dog := Dog new()
    printf("dog name = %s, dog age = %d\n", dog name, dog age)
    
}