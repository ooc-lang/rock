
describe("can access 'class' of both object and primitives types", ||
    expect("Foo", Foo new() class name)
    expect("Int", 42 class name)
    expect("String", "String" class name)
)

Foo: class {
    init: func
}
