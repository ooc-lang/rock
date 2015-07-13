
//! shouldfail

// Test for https://github.com/fasterthanlime/rock/issues/626

result := 0

describe("", ||
    foo := Foo<Bar> new(Bar clear)
    foo doThing()
    expect(42, result)
)

Foo: cover template<T> {
    fn: Func <T> (T)

    init: func@ (=fn)

    doThing: func {
        fn(42)
    }
}

Bar: class {
    clear: static func (i: Int) {
        result = i
    }
}


