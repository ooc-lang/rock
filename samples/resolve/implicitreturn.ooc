main: func {
    eval(32) println()
    eval(45) println()
}

eval: func (i: Int) -> String {
    if(i > 42) {
        "Too hot!"
    } else {
        "Too cold!"
    }
}
