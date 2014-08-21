main: func {
    a := null as String

    a = a ?? "test"

    if(a != "test") {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
