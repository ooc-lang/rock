f: func -> (Int, Int, Int) { (1, 2, 3) }
g: func -> (Int, Int, Int) { f() }

main: func {
    (a, b, c) := g()
    if (a != 1 || b != 2 || c != 3) {
        "Fail! (a = %d, b = %d, c = %d)" printfln(a, b, c)
        exit(1)
    }

    "Pass" println()
}
