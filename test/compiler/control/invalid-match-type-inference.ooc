
//! shouldfail

// There's no common ancestor between String and Int, so
// match can't infer its type.
f: func -> Int {
    if(true) {
        match {
            case true => "Hi!"
            case      => 42
        }
    } else {
        0
    }
}
