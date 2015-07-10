
// Test case for https://github.com/fasterthanlime/rock/issues/348

f: func -> Int[] {
    [1, 2, 3, 4]
}

describe("should be able to return array", ||
    a := f()
    expect(1, a[0])
    expect(2, a[1])
    expect(3, a[2])
    expect(4, a[3])
)
