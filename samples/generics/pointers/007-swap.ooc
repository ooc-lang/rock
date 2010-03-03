swap: func <T> (a, b: T) {
	c := a
	a = b
	b = c
}

main: func {
    a := 42
    b := 23
    printf("before, a = %d, b = %d\n", a, b)
    swap(a, b)
    printf("after, a = %d, b = %d\n", a, b)
}