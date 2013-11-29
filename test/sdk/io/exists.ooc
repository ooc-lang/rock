
import io/File

main: func {

    f := File new("some_unique_filename_hopefully")

    if (f exists?()) {
        "Fail! #{f path} should not exist." println()
        exit(1)
    }

    f write("Hello")

    if (!f exists?()) {
        "Fail! #{f path} should exist." println()
        exit(1)
    }

    f rm()

    if (f exists?()) {
        "Fail! #{f path} should no longer exist." println()
        exit(1)
    }

    "Pass" println()

}
