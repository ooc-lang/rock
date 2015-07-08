
describe("foreach should allow storing index in variable via tuple", ||
    a := "hello dolly"
    b := Buffer new()

    for ((i, c) in a) {
        expect(c, a[i])

        if (c == 'l') continue
        if (c == ' ') break

        b append(c)
    }
    result := b toString()

    expect("heo", result)
)
