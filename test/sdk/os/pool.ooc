import os/[Process, JobPool], math/Random

pool := JobPool new()
"Default parallelism = %d" printfln(pool parallelism)

for (i in 0..3) {
    duration := Random randInt(1, 4)
    "Sleeping for %d" printfln(duration)

    p := Process new(["sleep", duration toString()])
    p executeNoWait()
    pool add(Job new(p))
}

pool waitAll()
"All done!" println()

