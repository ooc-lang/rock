// regression test for: https://github.com/nddrylliog/rock/issues/641
// "ACS capture of referenced' variables"

call: func (f: Func) { f() }

setIntegerTo: func (dst: Int@, value: Int) {
    dst = value
}

main: func {
    score := -1
    call(|| setIntegerTo(score&, 42))
    "Score = %d" printfln(score)
}
