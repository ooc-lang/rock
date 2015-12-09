
Foo: class template <T> {
    val: T

    init: func (=val)    
}

IntWrapper: class extends Foo<Int> {
    init: super func

    addOne: func -> Int {
        val + 1
    }
}

describe("class templates should be extendable from non-template classes when totally qualified", ||
    i := IntWrapper new(42)
    expect(43, i addOne())
)
