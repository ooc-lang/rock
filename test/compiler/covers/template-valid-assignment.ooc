
Vec2: cover template <T> {
    x, y: T

    init: func@ (=x, =y)
}

main: func {
    vf1 := Vec2<Float> new(1.0, 1.0)
    vf1 = Vec2<Float> new(1.0, 1.0)

    "Pass!" println()
}
