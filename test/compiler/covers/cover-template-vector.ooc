
describe("a fairly complex cover template class", ||
    vf := Vec2<Float> new(1.0, 1.0)
    vf add!(1.0, 2.0)

    expect(2.0, vf x)
    expect(3.0, vf y)

    vi := Vec2<Int> new(3, 4)
    vi = vi add(4, 4)

    expect(7, vi x)
    expect(8, vi y)
)

// support code

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


