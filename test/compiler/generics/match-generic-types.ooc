
// Test for https://github.com/fasterthanlime/rock/issues/802

use sam-assert

getType: func <T> (t: T) -> String {
    match t {
        case i: Int =>
            "integer"
        case c: Cell =>
            "a cell!"
        case =>
            "not sure.."
    }
}

describe("should be able to match a generic type without writing its typeargs", ||
    expect("integer", getType(42))
    expect("a cell!", getType(Cell<Int> new(42)))
)

