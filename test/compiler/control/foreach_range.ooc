
main: func {
    j := 0
    total := 0
    for (i in 0..10) {
        total += 1
        if (i != j) {
            "Fail! i = %d, j = %d" printfln(i, j)
            exit(1)
        }
        j += 1
    }

    if (total != 10) {
        "Fail! total = %d" printfln(total)
        exit(1)
    }

    "Pass" println()
}
