
// Test for https://github.com/fasterthanlime/rock/issues/361

import structs/HashMap

describe("should be able to iterate over hashmap keys", ||
    hm := HashMap<String, String> new()
    hm put("foo", "bar")

    for (key in hm keys) {
        expect("foo", key)
    }
)

