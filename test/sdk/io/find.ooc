import io/File

main: func {
    base := File new("find_test")

    dir := File new(base, "some/deep/directory/structure")
    dir mkdirs()

    f1 := File new(dir, "blah.txt")
    f1 write("hello")
    f2 := File new(base, "blah.txt")
    f2 write("hallo")

    foundCount := 0
    base find(f1 name, |f|
        foundCount += 1
        true
    )
    base rm_rf()

    if (foundCount < 2) {
        "Should have found two instances of #{f1 name} in #{base path}" println()
        exit(1)
    }

    "Pass" println()
}
