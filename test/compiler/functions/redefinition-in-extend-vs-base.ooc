//! shouldfail

base: class{
    exists?: func -> Bool { return false }
}

extend base{
    exists?: func -> Bool { return true }
}
