
main: func {
    
    classify(2)
    classify(4)
    classify(89)
    
    return 0
    
}

classify: func (i: Int) {
    
    match (i) {
        case 2 => "Two,yay!"   println()
        case 4 => "Four, yay!" println()
        case   => "Huh, wtf?"  println()
    }
    
}
