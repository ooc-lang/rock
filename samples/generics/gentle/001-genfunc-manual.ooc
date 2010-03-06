printType: func (T: Class, object: Object) {
    
    printf("Got an object of type %s\n", T name)
    
}

Bird: class {}

main: func {
    
    bird := Bird new()
    printType(bird class, bird)
    
}
