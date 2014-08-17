//! shouldfail

Vec2: cover template <T> {
    x, y: T

    init: func@ (=x, =y)
}

main: func {
    vf := Vec2<Float> new(1.0, 1.0)
    vi := Vec2<Int> new(1, 1)

    vf = vi
}
