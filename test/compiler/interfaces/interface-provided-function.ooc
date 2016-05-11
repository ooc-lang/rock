Printable: interface {
    toString: func -> String

    print: func {
        toString() println()
    }
}

Foo: class implements Printable {
    count := static 0

    init: func {
        count += 1
    }

    toString: func -> String { "foo##{count}" }
}

describe("interfaces should be able to provide default implementations without rock crashing", ||
    expect("foo#1", Foo new() toString())
)
