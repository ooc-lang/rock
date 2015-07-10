
//! shouldfail

import structs/ArrayList

// Test case for https://github.com/fasterthanlime/rock/issues/842

describe("should refuse invalid generic assignment", ||
    data: ArrayList<ArrayList<Int>>
    data = ArrayList<Int> new()
    data add(ArrayList<Int> new)
    data[0] add(1)
)

