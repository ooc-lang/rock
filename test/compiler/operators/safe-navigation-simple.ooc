Foo: cover {
    bar: Bar
}

Bar: class {
    baz: Baz

    init: func (nil? := false) {
        if (nil?) {
            baz = null
        } else {
            baz = Baz new(this)
        }
    }
}

Baz: class {
    foo: Foo

    init: func (bar: Bar) {
        foo bar = bar
    }
}

describe("safe navigation operator should navigate into classes and covers", ||
    bar1 := Bar new()
    bar2 := Bar new(true)

    expect(bar1 $ baz $ foo bar, bar1)
    expect(bar2 $ baz $ foo bar, null)
)
