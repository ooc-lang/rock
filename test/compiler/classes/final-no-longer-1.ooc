//! shouldfail

A: class {
    init: func
    test: func
}

B: class extends A {
    init: func
    test: final func
}

C: class extends B {
    init: func
    test: func
}

