
print: func <T> (value: T) {
    
    printf("Got a %s of size %d\n", value)
    //printf("Got a %s of size %d\n", T name, T instanceSize)
    
}

Dog: class {
    
}

main: func -> Int {
    
    print(42)
    print("Hogfather")
    //print(Dog new())
    
}
