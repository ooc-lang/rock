
// Test for https://github.com/ooc-lang/rock/issues/890

Ditto: class {
    s: String
    init: func (=s)

    operator + (other: This) -> This {
        new(s + other s)
    }
}

Container: class {
    ditto := Ditto new("john")
    init: func
}

Peeker: class {
    inner: Object
    init: func (=inner)
    peek: func <T> (T: Class) -> T { inner }
}

describe("should unwrap += correctly even with returnArgs", ||
    c := Container new()
    p := Peeker new(c)

    // forced to unwrap, only has '+' operator
    p peek(Container) ditto += Ditto new(" doe")

    expect("john doe", c ditto s)
)

