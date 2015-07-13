
done := false

main: func {
    myFunc: Func (Int)
    myFunc_imp := func (i: Int) { done = true }
    myFunc = myFunc_imp

    myFunc(3)
    expect(true, done)
    "Pass" println()
}
