
//! shouldfail

// Test for https://github.com/fasterthanlime/rock/issues/825

Foo: class { init: func }

falafel: func <Tuvalu> (a, b: Tuvalu) -> String {
    Tuvalu name
}

describe("should refuse to reconcile irreconcilable types", ||
    type := falafel(42, Foo new())
    expect("Foo", type)
)


