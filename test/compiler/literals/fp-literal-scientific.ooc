
check: func <T> (t: T, ref: Class) {
    if (T != ref) {
        "Fail! expected #{ref name}, got #{T name}" println()
        exit(1)
    }
}

checkDouble: func (a, b: Double) {
    if (a != b) {
        "Fail! Expected a == b, but got a = %f, b = %f" printfln(a, b)
        exit(1)
    }
}

checkFloat: func (a, b: Float) {
    if (a != b) {
        "Fail! Expected a == b, but got a = %f, b = %f" printfln(a, b)
        exit(1)
    }
}

main: func {
    check(3.14e+0, Double)
    check(3.14E+3, Double)
    check(314.0E-2, Double)
    check(3.14e+0f, Float)
    check(3.14E+3f, Float)
    check(314.0E-2f, Float)

    checkDouble(3.14e+0, 3.14)
    checkDouble(3.14E+3, 3140.0)
    checkDouble(314.0E-2, 3.14)
    checkFloat(3.14e+0f, 3.14f)
    checkFloat(3.14E+3f, 3140.0f)
    checkFloat(314.0E-2f, 3.14f)

    "Pass" println()
}

