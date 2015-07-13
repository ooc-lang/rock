
use sam-assert

takeArray: func (arr: Int[]) -> Int {
    expect(42, arr[0])
    1
}

describe("function call should be able to take array literal", ||
    p := takeArray([42, 47, 53])
)

