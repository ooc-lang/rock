
// Not linked to any issue in particular, just a regression test
// for when we refactor the generics code again.

import structs/Stack

done := false

describe("type args should be inferred from type hierarchy", ||
    t := Trail new()

    for (tuvalu in t backward()) {
        tuvalu doStuff()
    }

    expect(true, done)
)

// Support code

Node: class {
    init: func
    doStuff: func {
        done = true
    }
}

Trail: class extends Stack<Node> {
    init: func {
        super()
        push(Node new())
    }
}

getType: func <T> (t: T) -> String {
    T name
}

