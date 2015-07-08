
// regression test for: https://github.com/fasterthanlime/rock/issues/885

describe("should call static function from closure", ||
    f := func {
        // woof!
    }
    f()
)

