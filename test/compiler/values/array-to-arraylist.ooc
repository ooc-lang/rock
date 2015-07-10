
import structs/ArrayList
use sam-assert

describe("should be able to cast array to ArrayList", ||
    keys := ["fee", "fie", "foo", "fum"] as ArrayList<String>
    expect("fee", keys get(0))
)

