import os/Env

main: func {
    Env set("COW", "MOO")
    "COW is: '%s'" format(Env get("COW")) println()
    Env unset("COW")
    "COW is: '%s'" format(Env get("COW")) println()
}
