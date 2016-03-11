
// test for https://github.com/ooc-lang/rock/issues/886

formatInt: func (i: Int) -> String {
    "~#{i}"
}

Something: cover template <T> {

    init: func

    format: func (t: T) -> String {
        "+#{t}"
    }

}

describe("string interpolation in cover templates", ||
    expect("~42", formatInt(42))
    expect("+42", Something<Int> new() format(42))
    expect("+hi", Something<String> new() format("hi"))
)

