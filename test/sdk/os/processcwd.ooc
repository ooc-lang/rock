import os/Process

p := Process new(["cat", "hosts"])
p setCwd("/etc")
p execute()
