

main: func {
    s := (1, 5) as S
    a := s&
    b := s&

    expect(b, a)
}

// Support code

S: cover {
    x, y: Int
}

