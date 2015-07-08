
//! shouldfail

Vec2: cover {
    x, y: Float
}

Something: cover template <T> {

    init: func

    format: func (t: T) -> String {
        "+#{t}"
    }

}

Something<Vec2> new() format((1.0f, 2.0f) as Vec2)

