

//! shouldfail

// Test for https://github.com/ooc-lang/rock/issues/811

Foo: class {
    done: Bool { get {
        this lock<Bool>(f)
    } }
}
