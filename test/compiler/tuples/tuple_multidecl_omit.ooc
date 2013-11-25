
main: func {
    one()
    two()
    three()

    "Pass" println()
}

one: func {
    (a, b, _) := foo()

    if (a != 1 || b != 2) {
        "Fail! (one) a = %d, b = %d" printfln(a, b)
        exit(1)
    }
}

two: func {
    (a, _, b) := foo()

    if (a != 1 || b != 3) {
        "Fail! (two) a = %d, b = %d" printfln(a, b)
        exit(1)
    }
}

three: func {
    (_, a, b) := foo()

    if (a != 2 || b != 3) {
        "Fail! (two) a = %d, b = %d" printfln(a, b)
        exit(1)
    }
}

foo: func -> (Int, Int, Int) {
    (1, 2, 3)
}

