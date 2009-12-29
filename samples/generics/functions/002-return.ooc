
get: func <T> (t: T) -> T {
    
    a := 42
    return a
    
}

main: func -> Int {
    
    a : Int
    a = get(21)
    printf("The answer is %d\n", a)
    return 0
    
}
