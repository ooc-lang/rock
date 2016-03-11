Foo: cover {
    calculated ::= 42
}

describe("should be able to directly use a calculated property of a cover stored in an ooc array", ||
    arr := Foo[1] new()
    foo: Foo
    arr[0] = foo

    expect(42, arr[0] calculated)
)
