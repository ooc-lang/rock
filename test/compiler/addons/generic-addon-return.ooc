extend Cell <T> {
    id: func -> T {
        return val
    }
}

describe("we should be able to return values of a generic type in generic addon", ||
    cell := Cell new("hi")
    expect("hi", cell id())
)
