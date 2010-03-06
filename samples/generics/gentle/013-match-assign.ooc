myFunc: func <T> (blub: T) -> T {
    value : T = match {
        case true => "hohoho, it works."
    }
    return value
}

main: func {
    myFunc(42) as String println()
}
