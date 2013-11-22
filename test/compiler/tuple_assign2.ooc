
main: func {
    a, b: Int

    (a, b) = Duplicator dup(42)
}

Duplicator: class {
    dup: static func (a: Int) -> (Int, Int) {
        (a, a)
    }
}
