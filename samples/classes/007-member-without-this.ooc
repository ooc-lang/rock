
Robot: class {
    
    name : String
    
    init: func (.name) { this name = name }
    
    boast: func {
        printf("I, %s, am the single greatest robot ever. Ever.\n", name)
    }
    
}

main: func {
    
    Robot new("Pintsize") boast()
    
}
