
main: func {
    success := true

    // https://github.com/nddrylliog/rock/issues/324
    "Test for #324..." println()
    s := "\033[36myay\033[0m"
    if (s size != 12) {
        "[FAIL] Size should be 12, is %d" printfln(s size)
        success = false
    } else {
        "[PASS]" println()
    }

    // https://github.com/nddrylliog/rock/issues/651
    "Test for #651..." println()
    s2 := "\163"
    if (s2 size != 1) {
        "[FAIL] Size should be 1, is %d" printfln(s2 size)
        success = false
    } else {
        "[PASS]" println()
    }

    exit(success ? 0 : 1)
}
