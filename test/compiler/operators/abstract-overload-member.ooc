
Matrix: abstract class {
    abstract operator [] (index: Int) -> Int

    getFirst: func -> Int {
        this[0]
    }
}

Vec3: class extends Matrix {
    a, b, c : Int
    init: func (=a, =b, =c)

    operator [] (index: Int) -> Int {
        match (index) {
            case 0 => a
            case 1 => b
            case 2 => c
        }
    }
}

main: func {
    matrix := Vec3 new(2, 4, 6)

    if(matrix getFirst() != 2 || matrix[1] != 4 || matrix[2] != 6) {
        "Fail!" println()
        exit(1)
    }

    "Pass" println()
    exit(0)
}
