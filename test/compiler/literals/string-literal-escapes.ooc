
checkString: func (test: String, ref: Int) {
    val := test[0] as UChar
    if (val != ref) {
        "'#{test}' should be #{ref}, is #{val}" println()
        exit(1)
    }
}

checkChar: func (test: Char, ref: Int) {
    val := test as UChar
    if (val != ref) {
        "'#{test}' should be #{ref}, is #{val}" println()
        exit(1)
    }
}

main: func {
    checkString("\0", 0)
    checkString("\r", 13)
    checkString("\n", 10)
    checkString("\a", 7)
    checkString("\t", 9)
    checkString("\v", 11)
    checkString("\377", 255)
    checkString("\xff", 255)

    checkChar('\0', 0)
    checkChar('\r', 13)
    checkChar('\n', 10)
    checkChar('\a', 7)
    checkChar('\t', 9)
    checkChar('\v', 11)
    checkChar('\377', 255)
    checkChar('\xff', 255)

    "Pass" println()
}
