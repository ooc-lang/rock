
describe("should allow statis funcs in addon", ||
    bar := Foo bar()
    expect(42, bar x)
)

// support code

Foo: class {
    x: Int

    init: func(=x)
}

extend Foo {
    bar: static func -> This {
        Foo new(42)
    }
}


