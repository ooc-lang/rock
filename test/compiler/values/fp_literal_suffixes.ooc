
check: func <T> (t: T, ref: Class) {
    if (T != ref) {
        "Fail! expected #{ref name}, got #{T name}" println()
        exit(1)
    }
}

main: func {
    check(3.5, Double)
    check(3.5d, Double)
    check(3.5f, Float)
}

