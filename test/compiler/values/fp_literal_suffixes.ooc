
check: func <T> (t: T, ref: Class) {
    if (T != ref) {
        "Fail! expected #{ref name}, got #{T name}" println()
        exit(1)
    }
}

main: func {
    check(3.5, Double)
    check(3.5f, Float)
    check(3.5F, Float)
    check(3.5l, LDouble)
    check(3.5L, LDouble)

    "Pass" println()
}

