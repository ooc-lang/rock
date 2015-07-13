
use sam-assert

describe("casting to ooc array should allocate & memcpy", ||
    carr: Int* = gc_malloc(Int size * 3)
    carr[0] = 1
    carr[1] = 2
    carr[2] = 3

    arr := carr as Int[3]
    expect(1, arr[0])
    expect(2, arr[1])
    expect(3, arr[2])
)

