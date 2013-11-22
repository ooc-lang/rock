
main: func {
    a, b: Int

    (a, b) = dup(42)
}

dup: func (a: Int) -> (Int, Int) {
    (a, a)
}
