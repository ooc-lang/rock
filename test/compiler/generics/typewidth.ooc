
check: func <T> (t: T, name: String) {
    match (T name) {
        case name =>
            // good
        case =>
            "Fail, expected: " print()
            name print()
            ", got: " print()
            T name println()
            exit(1)
    }
}

IntPointer: cover from Int*

main: func {
    a: Int* = [1, 2, 3]
    check(a, "Pointer")
    check(func {}, "Pointer")
    check("Hello", "String")
    "Pass" println()
}

