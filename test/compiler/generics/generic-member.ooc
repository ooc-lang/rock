
// Test for https://github.com/fasterthanlime/rock/issues/889

describe("accessing generic member should not require a cast", ||
    g := Gift<String> new("hi")
    g tuvalu println()
)

Gift: class <T> {
    tuvalu: T
    init: func (=tuvalu)
}
