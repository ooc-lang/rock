
main: func {
    a := "hello dolly"
    b := Buffer new()

    for ((i, c) in a) {
        if (a[i] != c) {
            "Fail! a = %s, i = %d, c = %c" printfln(a, i, c)
            exit(1)
        }

        if (c == 'l') continue
        if (c == ' ') break

        b append(c)
    }
    result := b toString()

    if (result != "heo") {
        "Fail! result = %s" printfln(result)
        exit(1)
    }

    "Pass" println()
}
