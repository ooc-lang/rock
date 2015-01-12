// cf. https://github.com/fasterthanlime/rock/pull/853
First: class {
    init: func
    test: func
}

Second: class extends First {
    init: func
    test: final func
}

s := Second new()
s test()
"Pass" println()
