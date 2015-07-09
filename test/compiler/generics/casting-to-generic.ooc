
Peeker: class {
    inner: Object
    init: func (=inner)
    peek: func <T> (T: Class) -> T {
        inner as T // crashes because forgetting the & around (this->inner)
        // inner // works
    }
}

main: func {
    p := Peeker new("hi!")
    p peek(String) println()
}
