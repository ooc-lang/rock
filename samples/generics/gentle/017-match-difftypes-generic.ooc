retDouble: func() -> Double {
    return 3.142
}
retString: func() -> String {
    return "honey wine ftw!"
}
retBool: func() -> Bool {
    return true
}

test: func<T> (arg: T) -> T{

    return match T {
        case String => retString()
        case Double => retDouble()
        case Bool   => retBool()
    }
}

main: func() {
    
    test("beer!") println()
    test(3.142) toString() println()
    test(false) toString() println()
}
