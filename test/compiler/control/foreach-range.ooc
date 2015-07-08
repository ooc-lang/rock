
describe("foreach should iterate through range", ||
    j := 0
    total := 0
    for (i in 0..10) {
        total += 1
        expect(j, i)
        j += 1
    }

    expect(10, total)
)
