

//! shouldfail

// Test for https://github.com/fasterthanlime/rock/issues/811

Foo: class {
    done: Bool { get {
        this lock<Bool>(f)
    } }
}
