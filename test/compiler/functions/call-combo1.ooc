
// Test for https://github.com/fasterthanlime/rock/pull/901

describe("bar test()(1) should be recognized properly", ||
    bar := Foo new()

    a := bar test()
    a(1)

    bar test()(1)
)

// Support code

Foo: class {
    v: Int
    isOdd: Bool {
        get { v % 2 == 1 }
    }

    isEven ::= v %2 == 0

    init: func

    test: func -> Func (Int) {
        return func (a: Int) { a toString() println()}
    }
}


