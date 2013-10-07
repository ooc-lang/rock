import os/Process, structs/HashMap

p := Process new(["bash", "-c", "echo $MYVAR"])

env := HashMap<String, String> new()
env put("MYVAR", "42")
p setEnv(env)

p execute()
output := p getOutput()

"output = %s" printfln(output)
