import os/Process

p := Process new(["cat", "/etc/hosts"])
p execute()
