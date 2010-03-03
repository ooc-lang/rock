Yay: class <T> {
    message: T

    printy: func {
        message as String println()
    }

    setMessage: func(=message) {}
}

main: func {

	Yay<String> new() setMessage("Yodel?") .printy()

}
