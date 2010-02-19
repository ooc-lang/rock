
getMessage: func <T> (T:Class) -> T {
    return "Good!"
    return "Bad.."
}

main: func {
    getMessage(String) println()
}
