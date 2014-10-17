foo: func<T>(i: T){ }
bar: func<T, R>(i: T, j: R){ }

foo<Int>(1)
foo(1)

bar<Int, String>(1, "")
bar<Int>(1, "")
bar(1, "")
