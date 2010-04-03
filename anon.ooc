//import internals/yajit/Partial

main: func {
    a := "a"
    b := func { a println() }
    b()
}

