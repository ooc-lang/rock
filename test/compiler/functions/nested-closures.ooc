
// cf. https://github.com/fasterthanlime/rock/issues/882

describe("nested closures should be able to modify outer variable by ref", ||
    g := (1, 0) as Tuple
    please(||
        g = (2, 0) as Tuple
        please(||
            g = (3, 0) as Tuple
        )
    )
    expect(3, g a)
)

describe("nested closures should not capture outer closure by ref by default", ||
    g := (1, 0) as Tuple
    please(||
        g a = 2
    )
    expect(1, g a)
)

// support code

Tuple: cover {
    a, b: Int
}

please: func (f: Func) { f() }
