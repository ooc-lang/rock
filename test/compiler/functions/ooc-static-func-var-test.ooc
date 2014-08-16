// regression test for: https://github.com/nddrylliog/rock/issues/635
// "Can't call static first-class functions without the class name."
Dog: class {
    onBark: static Func
    bark: static func {
        // onBark should resolve to Dog.onBark static var Func
        onBark()
    }
}

main: func {
    Dog onBark = func {
        "woof" println()
    }
    Dog bark()
}
