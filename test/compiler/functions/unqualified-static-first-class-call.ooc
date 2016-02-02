
// regression test for: https://github.com/ooc-lang/rock/issues/635
// "Can't call static first-class functions without the class name."

// Don't use sam-assert, otherwise we hit #885
main: func {
    Dog onBark = func {
        "woof" println()
    }
    Dog bark()
}

// Support code

Dog: class {
    onBark: static Func
    bark: static func {
        // onBark should resolve to Dog.onBark static var Func
        onBark()
    }
}
