
main: func {
    one()

    "Pass" println()
}

one: func {
    a := 1
    b := 2
    (a, b) = (b, a + b)

    if (a != 2 || b != 3) {
        "Fail! (one) a = %d, b = %d" printfln(a, b)
        exit(1)
    }
}
