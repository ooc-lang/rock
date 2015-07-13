
// Test for https://github.com/fasterthanlime/rock/issues/783

describe("it should be legal to compare the address of structs", ||
    s := (1, 5) as S
    a := s&
    b := s&

    expect(b, a)
)

// Support code

S: cover {
    x, y: Int
}

