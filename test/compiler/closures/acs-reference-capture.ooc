// regression test for: https://github.com/nddrylliog/rock/issues/641
// "ACS capture of referenced' variables"

describe("using a var's reference should capture byref", ||
    score := -1
    call(|| setIntegerTo(score&, 42))
    expect(42, score)
)

// support code

call: func (f: Func) { f() }

setIntegerTo: func (dst: Int@, value: Int) {
    dst = value
}

