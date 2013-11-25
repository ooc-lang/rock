import structs/ArrayList into structs

main: func {
    a := structs ArrayList<Int> new()
    a add(1)
    a add(2)
    a add(3)

    if (a size != 3) {
        "Fail! a size = %d" printfln(a size)
        exit(1)
    }

    "Pass" println()
    exit(0)
}

