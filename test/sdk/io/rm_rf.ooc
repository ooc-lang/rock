import io/File

main: func {
    base := File new("rm_rf_test")

    dir := File new(base, "some/deep/directory/structure")
    dir mkdirs()

    if (!dir exists?()) {
        "#{dir path} should exist!" println()
        exit(1)
    }

    f1 := File new(dir, "blah.txt")
    f1 write("hello")
    f2 := File new(dir, "blih.txt")
    f2 write("hallo")

    if (!base rm_rf()) {
        "#{base path} rm_rf() should have returned true" println()
        exit(1)
    }

    checkDisappearance := func (f: File) {
        if (f exists?()) {
            "#{f path} should no longer exist!" println()
            exit(1)
        }
    }

    checkDisappearance(f1)
    checkDisappearance(f2)
    checkDisappearance(dir)
    checkDisappearance(base)

    "Pass" println()
}
