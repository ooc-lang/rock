
// Test for https://github.com/fasterthanlime/rock/issues/595

use sam-assert

describe("accessing & assigning references instead closures should work", ||
    a : Int@ = gc_malloc(Int size)
    a = 42
    f := func {
        expect(42, a)
    }
    f()
)
