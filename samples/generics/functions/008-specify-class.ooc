
get: func <T> (T: Class) -> T {

    if(T == Int) {
        return 42
    } else if(T == Float) {
        return 3.14
    } else if(T == String) {
        return "The answer is"
    }
    
    return
    
}

main: func -> Int {

    printf("%s %d, not %.2f\n", get(String), get(Int), get(Float))
    return 0
    
}
