
get: func <T> (t: T) -> T {
    
    return t as Int + 21
    
}

main: func -> Int {
    
    a := get(21)
    printf("The answer is %d\n", a)
    return 0
    
}
