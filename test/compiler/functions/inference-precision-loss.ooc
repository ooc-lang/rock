
kalamazoo: func ~Int    (a, b: Int)    -> String { "Int" }
kalamazoo: func ~Double (a, b: Double) -> String { "Double" }

check: func (result, signature, expected: String) {
    if (result != expected) {
        "Fail! expected (#{signature}) to call ~#{expected}, but got ~#{result} instead." println()
        exit(1)
    }
}

main: func {
    check(kalamazoo(1.0, 1.0), "Double, Double", "Double")
    check(kalamazoo(1.0, 1),   "Double, Int",    "Double")
    check(kalamazoo(1, 1.0),   "Int, Double",    "Double")
    check(kalamazoo(1, 1),     "Int, Int",       "Int")

    "Pass" println()
}

