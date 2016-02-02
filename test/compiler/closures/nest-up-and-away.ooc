
// Test for https://github.com/ooc-lang/rock/issues/907

finalValue: Int = 42

a := func {
    c: Int = 0
    b := func {
        c: Int = 1
        d := func {
            c: Int = 2
            e := func {
                finalValue = c
            }
            e()
        }
        d()
    }
    b()
}

describe("rock should generate valid code with any number of nested closures", ||
    a()
    expect(2, finalValue)
)

