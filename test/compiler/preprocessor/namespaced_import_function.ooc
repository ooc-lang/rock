import math into math

main: func {
    a := math abs(-3)

    if (a != 3) {
        "Fail! a = %d" printfln(a)
        exit(1)
    }

    "Pass" println()
    exit(0)
}

