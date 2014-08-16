
intDone := false
strDone := false

Dog: class {

    init: func ~int (a: Int) {
        intDone = true
    }
    
    init: func ~str (a: String) {
        strDone = true
    }

}

main: func {
    Dog new(42)
    Dog new("43")

    if (!intDone) {
        "Fail! intDone should be true" println()
        exit(1)
    }

    if (!strDone) {
        "Fail! strDone should be true" println()
        exit(1)
    }

    "Pass" println()
}
