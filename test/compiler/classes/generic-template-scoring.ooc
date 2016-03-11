//! shouldfail
Foo: class <U> template <T> {
    val: U
    init: func (=val)
}

takeAFoo: func (foo: Foo<Int, String>) {}

foo := Foo<String, String> new("hi there!")
takeAFoo(foo)
