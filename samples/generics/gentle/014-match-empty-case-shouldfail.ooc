myFunc: func <T> (blub: T) -> T {
    value : T = match {
        case false => // an empty case, in a match used as an expression
        case true => "hohoho, it should fail"
    }
    return value
}

main: func {
    myFunc(42) as String println()
}
