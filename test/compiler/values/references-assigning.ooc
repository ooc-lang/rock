
// Test for https://github.com/fasterthanlime/rock/issues/595

use sam-assert

describe("accessing & assigning references instead closures should work", ||
    alamanthus : Int@ = gc_malloc(Int size)
    alamanthus = 42
    f := func {
        expect(42, alamanthus)
        alamanthus = 24
    }
    f()
    expect(24, alamanthus)
)
