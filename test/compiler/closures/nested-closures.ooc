
// cf. https://github.com/ooc-lang/rock/issues/882

describe("nested closures should be able to modify outer variable by ref", ||
    g := (1, 0) as Tuple
    please(||
        g = (2, 0) as Tuple
        please(||
            g = (3, 0) as Tuple
        )
    )
    expect(g a, 3)
)

describe("nested closures should not capture outer var by ref by default", ||
    g := (1, 0) as Tuple
    please(||
        g a = 2
    )
    expect(g a, 1)
)

describe("nested closures should capture outer var by ref when marked", ||
    g := (1, 0) as Tuple
    please(||
        please(||
            g = g
            g a = 2
        )
    )
    expect(g a, 2)
)

// support code

Tuple: cover {
    a, b: Int
}

please: func (f: Func) { f() }
