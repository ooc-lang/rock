
describe("should do implicit cast when returning", ||
    v := valuey()
    expect(3, v)
)

valuey: func -> Int {
    return 3.14
}

