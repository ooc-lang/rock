someVeryLongVariable: unmangled(shortName) Int
shortName: extern Int

main: func {
    someVeryLongVariable = 456
    "455 + 1 = %d" format(shortName) println()
}
