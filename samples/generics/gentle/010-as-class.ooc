A: class {
    f: func <T> (T: Class) -> T {
        return 42
    }
}

main: func {
	a := A new()
	a f(Int) toString() println()
}

