
import io/File

main: func {
    version (windows) {
        // there's no way that test runs on Win32
        "Skip" println()
        exit(0)
    }

    f := File new("some_unique_filename_hopefully")
    f write("hoy hoy")

    if (f executable?()) {
        "Fail! #{f path} should not be executable" println()
        exit(1)
    }

    f setExecutable(true)

    if (!f executable?()) {
        "Fail! #{f path} should be executable by now" println()
        exit(1)
    }

    f setExecutable(false)

    if (f executable?()) {
        "Fail! #{f path} should no longer be executable at this point" println()
        exit(1)
    }

    f rm()

    "Pass" println()

}

