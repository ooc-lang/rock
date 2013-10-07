import threading/Thread
import structs/ArrayList

threads := ArrayList<Thread> new()

mutex := RecursiveMutex new()
counter := 0

for (i in 0..42) {
    threads add(Thread new(||
        for (i in 0..10) mutex lock()
        counter += 1
        for (i in 0..10) mutex unlock()
    ))
}

for (t in threads) t start()
for (t in threads) t wait()

// prints counter = 42
"counter = %d" printfln(counter)

