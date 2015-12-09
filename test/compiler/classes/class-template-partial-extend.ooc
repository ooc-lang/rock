Foo: class template <T, U> {
    left: T
    right: U

    init: func (=left, =right)

    action: func -> T {
        left + right
    }
}

Bar: class template <T> extends Foo <Float, T> {
    init: func (=right) {
        left = 10.f
    }
}

describe("class templates should be extendable with any amount of inherited templates", ||
    bar := Bar<Int> new(32)
    expect(42.f, bar action())
)
