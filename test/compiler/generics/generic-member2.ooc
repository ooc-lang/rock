
// Test for https://github.com/ooc-lang/rock/issues/889

describe("should be able to assign, plus-assign, access generic member", ||
    g := Gift<Int> new(42)

    "#{g tuvalu}" println()
    expect(42, g tuvalu)

    g tuvalu = 10
    expect(10, g tuvalu)

    i: Int
    i = g tuvalu 
    expect(10, i)

    g tuvalu += 8
    expect(18, g tuvalu)
)

Gift: class <T> {
    tuvalu: T
    init: func (=tuvalu)
}

