import os/Process, structs/HashMap

main: func {
    env := HashMap<String, String> new()
    env put("MYVAR", "42")

    command := ["bash", "-c", "echo $MYVAR"]
    version (windows) {
        command = ["cmd", "/c", "echo %MYVAR%"]
    }

    p := Process new(command)
    p setEnv(env)
    p execute()
    output := p getOutput()
    output = output trim()
    if (output != "42") {
        "Fail! expected output = 42, but got #{output}" println()
        exit(1)
    }

    "Pass" println()
}
