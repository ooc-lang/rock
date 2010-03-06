Container: class <T> {}

printType: func <T> (cont: Container<T>) {
    printf("We got a %s of %s\n", cont class name, T name)
}

main: func {
    c := Container<Int> new()
    printType(c)
}
