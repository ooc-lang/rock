
main: func {
    a, b: Int

    (a, b) = dup(42)
    if (a != 42 || b != 43) {
        "Fail! (a, b) = dup(42)" println()
        exit(1)
    }

    (b, a) = (a, b)
    if (b != 42 || a != 43) {
        "Fail! (a, b) = dup(42)" println()
        exit(1)
    }

    "Pass" println()
}

dup: func (a: Int) -> (Int, Int) {
    (a, a + 1)
}
