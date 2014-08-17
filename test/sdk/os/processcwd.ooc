import os/Process

main: func {
    version (windows) {
        p := Process new(["cmd", "/c", "echo %TMP%"])
        tmpDir := p getOutput()
        tmpDir = tmpDir trim()

        p = Process new(["cmd", "/c", "cd"])
        p setCwd(tmpDir)
        cwd := p getOutput()
        cwd = cwd trim()

        if (cwd != tmpDir) {
            "Fail! expected cwd to equal #{tmpDir}, but got #{cwd} instead" println()
            exit(1)
        }
    } else {
        p := Process new(["cat", "hosts"])
        p setCwd("/etc")
        p execute()
    }

    "Pass" println()
}
