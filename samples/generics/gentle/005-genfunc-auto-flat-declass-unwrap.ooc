printType: func <T> (object: T) {
    printf("Got an object of type %s\n", T name)    
}

Bird: class {}

main: func {
    
    printType(b := Bird new())
    
}
