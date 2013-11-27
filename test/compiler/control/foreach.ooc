
main: func {
    a := "hello"
    b := Buffer new()

    for (c in a) {
        b append(c)
    }
    result := b toString()

    if (result != a) {
        "Fail! result = %s" printfln(result)
        exit(1)
    }

    "Pass" println()
}
