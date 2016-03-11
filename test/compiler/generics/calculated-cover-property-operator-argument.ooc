import structs/ArrayList

Foos: class {
    init: func
    operator [] (index: Int) -> Foo {
        Foo new(42)
    }
}

Foo: cover {
    bar: Int
    init: func@ (=bar)
}

describe("we should be able to call a generic function on a calculated property of a cover returned by an operator call", ||
    foos := Foos new()
    list := ArrayList<Int> new()

    list add(foos[0] bar)

    expect(42, list last())
)
