
Vec2: class {
    x, y: Float

    init: func (=x, =y)
}

operator - (v: Vec2) -> Vec2 {
    Vec2 new(-v x, -v y)
}

operator + (v: Vec2) -> Vec2 {
    Vec2 new(+v x, +v y)
}

main: func {
    v1 := Vec2 new(1.0, 1.0)
    v2 := +v1
    v3 := -v1

    if (v2 x != 1.0 || v2 y != 1.0) {
        "Fail! v2 = #{v2 x}, #{v2 y}" println()
        exit(1)
    }

    if (v3 x != -1.0 || v3 y != -1.0) {
        "Fail! v3 = #{v3 x}, #{v3 y}" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}

