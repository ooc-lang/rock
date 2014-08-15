
S: cover {
    x, y: Int
}

main: func {
    s := (1, 5) as S
    a := s&
    b := s&

    if (!(a == b)) {
        "Fail! expected a == b" println()
        exit(1)
    }

    "Pass" println()
}
