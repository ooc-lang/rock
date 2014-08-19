//! shouldfail

Foo: interface {
    bar: func -> String
}

Bar: class implements Foo {
    bar: func -> Int {
        0
    }
}
