get: func <T> (t: T) -> T {

    "Incorrect behavior!" println()    
    return t as Int + 21
    
    // To compile under j/ooc, use the following workaround:
    
    // answer := t as Int + 21
    // return answer
    
}

main: func -> Int {

    // the correct behavior here is *NOT* to call the get() method
    // however, j/ooc will call it, no matter what the condition is.
    // rocks does it the right way - with a CommaSequence.
    // look at the generated code
    
    printf("The answer is %d\n", false ? get(-4) : 42)
    return 0
    
}
