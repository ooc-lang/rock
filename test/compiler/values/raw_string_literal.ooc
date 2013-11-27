
fails := false

main: func {
    c := c"Hi, world."
    checkType(c, CString)

    s := c toString()
    checkType(s, String)

    if (s != "Hi, world.") {
        "Fail! expected 'Hi, world.', got '%s'" printfln(s)
        fails = true
    }

    if (fails) {
        "We've had errors" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}

checkType: func <T, U> (t: T, U: Class) {
    if (T != U) {
        fails = true
        "Fail! expected a %s, got a %s" printfln(U name, T name)
    }
}

