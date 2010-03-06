/*
test: func <T> (blah: T) {

    var: T
    var = 13
    
}

thirteen: func -> Int { 13 }
*/

test: func<T> (blub: T) -> T {

    result: T
    match T {
        case String => result = "abcd"
        case Bool   => result = true
        case        => result = null
    }
    return result
}

main: func() {
    
    test("42") as String println()
    test(true) as Bool toString() println()
    (test(42) ? "non-null" : "null") println()
    
}
