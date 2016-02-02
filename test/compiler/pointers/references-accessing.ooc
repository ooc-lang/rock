
// Test for https://github.com/ooc-lang/rock/issues/595

describe("accessing references inside closures should work", ||
    a : Int@ = gc_malloc(Int size)
    a = 42
    f := func {
        expect(42, a)
    }
    f()
)
