Container: class <T> {
    
    printType: func {
        printf("Got a %s of type %s\n", class name, T name) 
    }
    
}

Bird: class {}

main: func {
    
    cont := Container<Bird> new()
    cont printType()
    
}

