Foo: cover {
    bar: Int
}

Bar: cover from Foo extends Foo

describe("rock should generate correct code for accesses of members of underlying covers", ||
    f: Bar
    f bar = 2

    expect(f bar, 2)
)
