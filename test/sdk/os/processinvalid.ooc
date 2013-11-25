import os/Process

p := Process new(["i_do_not_exist/some_exec"])
p execute()
