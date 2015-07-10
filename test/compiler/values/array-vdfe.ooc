
use sam-assert

takeArray: func (arr: Int[]) {
    expect(42, arr[0])
}

describe("should be able to simply declare array", ||
    willow := [42, 47, 53]
    takeArray(willow)
)


