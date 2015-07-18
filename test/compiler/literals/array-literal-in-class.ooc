Foo: class{
    test := [1, 2, 3]
    init: func
}

Bar: class{
    test := static const [1, 2, 3]
    init: func
}

describe("ArrayLiteral should be correctly unwrapped",||
    foo := Foo new()
    assert(foo test[0] == 1)
    assert(foo test[1] == 2)
    assert(foo test[2] == 3)
    assert(Bar test[0] == 1)
    assert(Bar test[1] == 2)
    assert(Bar test[2] == 3)
)
