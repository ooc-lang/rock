
main: func {

    a := "a"
    b := "b"
    (a, b) = (b, a)

    if (a == "a" || b == "b") {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()

}
