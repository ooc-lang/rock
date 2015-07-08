
describe("foreach should support iterating through String (Iterable)", ||
    a := "hello"
    b := Buffer new()

    for (c in a) {
        b append(c)
    }
    result := b toString()

    expect(a, result)
)
