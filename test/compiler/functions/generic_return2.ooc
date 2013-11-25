
blooey: func <T> (T: Class) -> T {
    match T {
        case Int => 42
    }
}

kablooey: func <T> (T: Class) -> T {
    blooey(T)
}

main: func {
    v := kablooey(Int)
    if (v != 42) {
        "Fail! (v = %d)" printfln(v)
        exit(1)
    }

    "Pass" println()
}

