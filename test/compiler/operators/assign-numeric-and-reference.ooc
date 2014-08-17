
fails := false

main: func {
    one()
    two()

    if (fails) {
        "We've had failures" println()
        exit(1)
    }

    "Pass!" println()
}

one: func {
    a: Int = 42
    b: SizeT

    b = a
    if (b != 42) {
        "Fail! b = %d" printfln(b)
        fails = true
    }
}

two: func {
    b: SizeT
    assign(b&, 42)

    if (b != 42) {
        "Fail! b = %d" printfln(b)
        fails = true
    }
}

assign: func (b: SizeT@, a: Int) {
    b = a
}

