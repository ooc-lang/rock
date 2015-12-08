Foo: class {
    bar: Bar

    init: func (=bar)
}

Bar: class {
    str: String

    init: func (=str)
}

describe("safe navigation and nullco operators should work in conjuction", ||
    foo1 := Foo new(null)
    foo2 := Foo new(Bar new("hi"))
    foo3 := Foo new(Bar new(null))

    expect(foo1 $ bar $ str ?? "nothing", "nothing")
    expect(foo2 $ bar $ str ?? "nothing", "hi")
    expect(foo3 $ bar $ str ?? "nullstr", "nullstr")
)
