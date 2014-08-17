import io/File

main: func {
    f := File new("blah.txt")
    f write("hello")

    if (!f exists?()) {
        "#{f path} should exist!" println()
        exit(1)
    }
    f rm()

    if (f exists?()) {
        "#{f path} should no longer exist!" println()
        exit(1)
    }

    "Pass" println()
}
