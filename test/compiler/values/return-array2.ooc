
// Test case for https://github.com/fasterthanlime/rock/issues/795

//! shouldfail

f: func -> Int[] {
    [1.0, 2.0, 3.0, 4.0]
}

describe("should not be able to return wrong array", ||
    a := f()
    expect(1, a[0])
    expect(2, a[1])
    expect(3, a[2])
    expect(4, a[3])
)
