
check: func <T> (t: T, ref: Class) {
    if (T != ref) {
        "Fail! expected #{ref name}, got #{T name}" println()
        exit(1)
    }
}

checkValue: func (val, ref: UInt) {
    if (val != ref) {
        "Fail! expected #{ref}, got #{val}" println()
        exit(1)
    }
}

main: func {
    check(42, Int)
    check(42u, UInt)
    check(42U, UInt)
    check(42l, Long)
    check(42L, Long)
    check(42ll, LLong)
    check(42LL, LLong)
    check(42ull, ULLong)
    check(42ULL, ULLong)

    checkValue(0b101010u, 42u)
    checkValue(0b000000101010u, 42u)
    checkValue(0c52u, 42u)
    checkValue(0x2au, 42u)

    "Pass" println()
}

