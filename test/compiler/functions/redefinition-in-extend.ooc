//! shouldfail

import structs/ArrayList

extend ArrayList<T> {
    exists?: func -> Bool{
        return false
    }
}

extend ArrayList<t> {
    exists?: func (i: String) -> Bool{
        return true
    }
}
