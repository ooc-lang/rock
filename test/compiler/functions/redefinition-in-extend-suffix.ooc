
import structs/ArrayList

describe("redefinition in extend with suffix should work", ||
    a := ArrayList<Int> new()
    expect(false, a exists?())

    b := ArrayList<String> new()
    expect(true, b exists?("hello"))
)

// support code

extend ArrayList<Int> {
    exists?: func -> Bool {
        return false
    }
}

extend ArrayList<String> {
    exists?: func ~string (i: String) -> Bool{
        return true
    }
}

