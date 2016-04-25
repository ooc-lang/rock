Foo: class <T> {
    val: T

    init: func(=val)

    printClass: func {
        T name println()
    }
}


extend Foo <T> {
    id: func -> T {
        val
    }

    equals?: func (other: Foo<T>) -> Bool {
        val == other val
    }
}

describe("we should be able to extend a generic class generically", ||
    foo1 := Foo new(42)
    foo2 := Foo new(42)

    expect(false, foo1 equals?(foo2))
    expect(true, foo1 id() == foo2 id())
)
