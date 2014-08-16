
Vec2: class {
    x, y: Float

    init: func (=x, =y)

    operator [] (index: Int) -> Float {
        match index {
            case 0 => x
            case 1 => y
            case => raise("Invalid index: #{index}"); 0.0
        }
    }
}

main: func {
    v1 := Vec2 new(1.0, 2.0)

    if (v1[0] != 1.0 || v1[1] != 2.0) {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}

