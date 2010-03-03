Box: class <T> {
    value: T

    init: func (v: T) {
        value = v
    }
}

testLocal: func <T> (T: Class) -> T {
    box := Box new("Hey there!")
	value := box value
	value
}

testMember: func <T> (T: Class) -> T {
    box := Box new("Hey there!")
    box value as T
}

main: func {
    testLocal(String) println()
	testMember(String) println()
}
