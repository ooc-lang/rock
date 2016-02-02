
// cf. https://github.com/ooc-lang/rock/pull/853

describe("methods can become final in subclasses (should compile)", ||
    Second new() test()
)

// suppport code

First: class {
    init: func
    test: func
}

Second: class extends First {
    init: func
    test: final func
}
