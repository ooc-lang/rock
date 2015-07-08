
describe("foreach should iterate through range with index", ||
    iterations := 0

    for ((i, x) in 0..10) {
        iterations += 1
        expect(x, i)
    }

    expect(10, iterations)
)
