
describe("should be able to assign cover templates of the same type", ||
    vf1 := Vec2<Float> new(1.0, 1.0)
    vf1 = Vec2<Float> new(1.0, 1.0)

    expect(vf1 x, vf1 y)
)

Vec2: cover template <T> {
    x, y: T

    init: func@ (=x, =y)
}

