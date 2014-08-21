operator ?? (l, r: Int) -> Int {
    r
}

main: func {
    if ((1 ?? 2 ?? 3) != 3) {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
