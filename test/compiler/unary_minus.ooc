
Vec2: class {
    x, y: Float

    init: func (=x, =y)
}

main: func {
    v1 := Vec2 new(1.0, 1.0)
    v2 := Vec2 new(v1 x * 1.0, - v1 y * 1.0)

    if (v2 x != 1.0 || v2 y != -1.0) {
        "Fail! v2 = #{v2 x}, #{v2 y}" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}

