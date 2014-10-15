//! shouldfail
import structs/ArrayList

extend ArrayList<Int>{
    exists?: func -> Bool{
        return false
    }
}

extend ArrayList<String>{
    exists?: func(i: String) -> Bool{
        return true
    }
}
