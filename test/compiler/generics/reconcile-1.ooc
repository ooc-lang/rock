
// Test for https://github.com/ooc-lang/rock/issues/825

Foo: class { init: func }
Bar: class extends Foo { init: super func }

falafel: func <Tuvalu> (a, b: Tuvalu) -> String {
    Tuvalu name
}

describe("should infer to common root, not first generic arg", ||
    type := falafel(Bar new(), Foo new())
    expect("Foo", type)
)

