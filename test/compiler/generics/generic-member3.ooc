
// Test for https://github.com/fasterthanlime/rock/issues/889

import structs/ArrayList

describe("should be able access member with its own typeargs", ||
    g := Gift<String> new("hi")
    g list get(0) println()
)

Gift: class <T> {
    list: ArrayList<T>
    init: func (t: T) {
        list = ArrayList<T> new()
        list add(t)
    }
}

