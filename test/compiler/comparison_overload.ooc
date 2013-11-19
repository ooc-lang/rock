
Number: class {
    x: Int

    init: func (=x)
}

operator <=> (n1, n2: Number) -> Int {
    n1 x <=> n2 x
}

main: func {
    n1 := Number new(13)
    n2 := Number new(42)

    if (n1 > n2) {
        "Fail! (n1 > n2)" println()
        exit(1)
    }

    if (n2 < n1) {
        "Fail! (n2 < n1)" println()
        exit(1)
    }

    if (n2 == n1) {
        "Fail! (n2 == n1)" println()
        exit(1)
    }

    if (!(n2 != n1)) {
        "Fail! (n2 != n1)" println()
        exit(1)
    }

    if ((n1 <=> n2) != -1) {
        "Fail! (n1 <=> n2)" println()
        exit(1)
    }

    if ((n2 <=> n1) != 1) {
        "Fail! (n2 <=> n1)" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}

