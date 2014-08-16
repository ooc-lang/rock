
valuey: func -> Int {
    return 3.14
}

main: func {
    v := valuey()
    if (v != 3) {
        "Fail! (v = %d)" printfln(v)
        exit(1)
    }

    "Pass" println()
}

