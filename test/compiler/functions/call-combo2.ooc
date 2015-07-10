
//!shouldfail

// Test for https://github.com/fasterthanlime/rock/pull/901

describe("bar test()() should be a compile error (args mismatch)", ||
    bar := Foo new()
    bar test()()
)

// Support code

Foo: class {
    v: Int
    isOdd: Bool {
        get { v % 2 == 1 }
    }

    isEven ::= v %2 == 0

    init: func

    test: func {}
}


