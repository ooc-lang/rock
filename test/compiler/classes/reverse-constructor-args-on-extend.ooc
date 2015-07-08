
A: class {
    init: func (callback: Func (Int), value: Int)
}

B: class extends A { // Wrong order of parameters
    init: func (value: Int, callback: Func (Int))
}
