
use sam-assert

takeArray: func (arr: Int[]) {
    expect(42, arr[0])
}

describe("function call should be able to take array literal", ||
    takeArray([42, 47, 53])
)

