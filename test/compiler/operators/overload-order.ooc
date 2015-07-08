
use sam-assert

Point2D: class {
    x, y: Int
    init: func(=x, =y)
    operator - -> This { This new(-this x, -this y) }
    operator - (other: This) -> This { This new(this x - other x, this y - other y) }
}

describe("operator overload order should not matter", ||
    p := Point2D new(2, 3)
    p2 := Point2D new(1, 1)
    p -= p2

    expect(1, p x)
    expect(2, p y)
)
