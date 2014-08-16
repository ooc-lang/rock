
main: func {
    one()
    two()

    "Pass" println()
}

one: func {
    (a, b) := ("a", "b")

    if (a != "a" || b != "b") {
        "Fail! (one) a = %s, b = %s" printfln(a, b)
        exit(1)
    }
}

two: func {
    (a, b) := dup("a")

    if (a != "a" || b != "a bis") {
        "Fail! (two) a = %s, b = %s" printfln(a, b)
        exit(1)
    }
}

dup: func (s: String) -> (String, String) {
    (s, s + " bis")
}

