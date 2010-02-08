import io/File into IO

main: func {
    // This works! :)
    file := IO File new()

    // This fails! :(
    anotherFile := File new()
}
