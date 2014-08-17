import os/Process

main: func {
    p: Process
    version (windows) {
        p = Process new(["cmd", "/c", "ver"])
    } else {
        p = Process new(["cat", "/etc/hosts"])
    }
    p execute()
}
