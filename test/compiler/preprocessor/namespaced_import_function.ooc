import math into meth

main: func {
    a := meth abs(-3)

    if (a != 3) {
        "Fail! a = %d" printfln(a)
        exit(1)
    }

    "Pass" println()
    exit(0)
}

