myFunc: func <T> (T: Class) -> T {
    "value" as T // implicit return
}

main: func {

    myFunc(String) println()

}
