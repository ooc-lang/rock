
// Test for https://github.com/fasterthanlime/rock/issues/903

use sam-assert

describe("tuple variable decls should have precedence over members", ||
    bar := Foo new(1337)
    expect(1337, bar xolophan)
    expect(1337, bar yardenis)
)

// support code

Foo: class {
    xolophan := 1
    yardenis := 2
    init: func (=xolophan, =yardenis)
    init: func ~fromInt (input: Int) {
        (xolophan, yardenis) := This makeXY(input)
        init(xolophan, yardenis)
    }
    makeXY: static func (input: Int) -> (Int, Int) { (input, input) }
}
