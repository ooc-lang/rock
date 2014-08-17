
main: func {
    a, b: Int

    (a, b) = Duplicator dup(42)
    if (a != 42 || b != 43) {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
}

Duplicator: class {
    dup: static func (a: Int) -> (Int, Int) {
        (a, a + 1)
    }
}
