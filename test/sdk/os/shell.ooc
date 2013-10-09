import os/ShellUtils

file := ShellUtils findExecutable("autoconf")
match file {
    case null => "autoconf not found!"
    case => "found: %s" format(file path)
} println()

