
counter := 0

fun: func -> String {
    counter += 1
    ""
}

describe("Left side of the null coalescing operator should only be evaluated once", ||
    temp := fun() ?? "foo"

    expect(1, counter)
)
