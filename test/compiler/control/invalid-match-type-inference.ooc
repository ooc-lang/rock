//! shouldfail

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
