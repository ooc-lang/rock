
Dog: class {
    
    name: String
    name = "Dilbert"
    
    init: func {
        printf("Hi, my name is %s\n", name)
    }
    
}

main: func {
    Dog new()
}
