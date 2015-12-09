
Foo: cover template <T> {
    val: T

    init: func@ (=val)

    bar: func@ -> Bar<T> {
        Bar<T> new(this&)
    }
}

Bar: cover template <T> {
    ref: Foo<T>*

    init: func@ (=ref)
}

describe("we should be able to create cross-referencing cover templates", ||
    foo := Foo<Int> new(42)

    expect(foo&, foo bar() ref)
)
