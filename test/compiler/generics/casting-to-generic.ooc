
//! shouldfail

// Test for https://github.com/fasterthanlime/rock/issues/891

use sam-assert

Peeker: class {
    inner: Object
    init: func (=inner)
    peek: func <T> (T: Class) -> T {
        inner as T
    }
}

describe("casting to generic is forbidden", ||
    p := Peeker new("hi!")
    expect("hi!", p peek(String))
)
