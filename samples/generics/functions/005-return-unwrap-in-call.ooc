
get: func <T> (t: T) -> T {
    
    return t as Int + 21
    
}

main: func -> Int {
    
    printf("The answer is %d\n", get(21))
    return 0
    
}
