import os/Process

main: func {
    version (windows) {
        p := Process new(["i_do_not_exist/some_exec"])
        caught := false
        try {
            p execute()
        } catch (p: ProcessException) {
            caught = true
        }

        if (!caught) {
            "Fail! expected a ProcessException to be thrown" println()
            exit(1)
        }

        "Pass" println()
    } else {
        p := Process new(["i_do_not_exist/some_exec"])
        code := p execute()

        if (code == 0) {
            "Fail! expected non-zero code but got #{code}" println()
            exit(1)
        }

        "Pass" println()
    }
}
