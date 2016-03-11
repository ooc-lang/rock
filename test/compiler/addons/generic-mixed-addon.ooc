Foo: class <T> template <U> {
    val1: T
    val2: U

    init: func (=val1, =val2)
}

extend Foo<U, String> {
    int_val: func -> Int {
        val2 toInt()
    }
}

describe("we should be able to extend a generic template class", ||
    foo := Foo<Int, String> new(40, "2")
    expect(42, foo val1 + foo int_val())
)
