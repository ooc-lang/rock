
// cf. https://github.com/fasterthanlime/rock/issues/840
// and https://github.com/fasterthanlime/rock/pull/854

describe("generic properties should work", ||
    tbar := Foo<Int> new()
    tbar a = 1

    expect(1, tbar a as Int)
    expect(1, tbar b)

    tbar b = 2

    expect(2, tbar a as Int)
    expect(2, tbar b)
)

// support code

Foo: class <T> {
    init: func

    a: T
    b: T {
        get { a }
        set (c) { a = c }
    }
}

