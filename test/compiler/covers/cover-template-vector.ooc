
Vec2: cover template <T> {
    x, y: T

    init: func@ (=x, =y)

    clone: func -> This {
        new(x, y)
    }

    add!: func@ (.x, .y) {
        this x += x
        this y += y
    }

    add: func (.x, .y) -> This {
        c := clone()
        c add!(x, y)
        c
    }
}

main: func {
    vf := Vec2<Float> new(1.0, 1.0)
    vf add!(1.0, 1.0)

    if (vf x != 2.0 || vf y != 2.0) {
        "Fail! #{vf x}, #{vf y} should equal 2.0, 2.0" println()
        exit(1)
    }

    vi := Vec2<Int> new(3, 4)
    vi = vi add(4, 3)

    if (vi x != 7 || vi y != 7) {
        "Fail! #{vi x}, #{vi y} should equal 7, 7" println()
        exit(1)
    }

    "Pass" println()
}

