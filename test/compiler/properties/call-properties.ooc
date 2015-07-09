
//! shouldfail

// Test for https://github.com/fasterthanlime/rock/issues/860

Foo: class {
    b ::= 1
    init: func
}

foo := Foo new()
foo b()

