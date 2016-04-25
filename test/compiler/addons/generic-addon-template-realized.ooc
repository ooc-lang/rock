//! shouldfail

Foo: class template <T> {
    magic: static func -> T {
        42
    }
}

extend Foo<Int> {
    withMagic: static func -> Int {
        magic() + 1
    }
}

Foo<LLong> withMagic()
