
// regression test for: https://github.com/ooc-lang/rock/issues/885

describe("should call static function from closure", ||
    f := func {
        // woof!
    }
    f()
)

