
check: func <T> (t: T) {
    if (T size != Pointer size) {
        "Fail! T size should be #{Pointer size}, is #{T size}" println()
        exit(1)
    }
}

main: func {
    a: Int*
    check(a)

    b: UInt64*
    check(b)

    c: Char*
    check(c)

    "Pass" println()
}
