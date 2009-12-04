Dog: class {
    
    name: String
    age: Int
    
    new: static func -> Dog {
        this := gc_malloc(Dog size) as Dog
        return this
    }
    
}

main: func {
    
    dog := Dog new()
    //printf("dog name = %s, dog age = %d\n", dog name, dog age)
    
}