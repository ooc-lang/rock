
main: func {
    iterations := 0

    for ((i, x) in 0..10) {
        iterations += 1
        if (i != x) {
            "Fail! expected i == x, but got i = %d, x = %d" printfln(i, x)
            exit(1)
        }
    }

    if (iterations != 10) {
        "Fail! expected 10 iterations, but did %d" printfln(iterations)
        exit(1)
    }

    "Pass" println()
}
