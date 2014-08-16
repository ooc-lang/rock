
blooey: func <T> (T: Class) -> T {
    match T {
        case Int => 42
    }
}

main: func {
    v := blooey(Int)
    if (v != 42) {
        "Fail! (v = %d)" printfln(v)
        exit(1)
    }

    "Pass" println()
}

