import threading/Thread
import structs/ArrayList

counter := 0

mutex := Mutex new()

threads := ArrayList<Thread> new()
for (i in 0..10) {
    threads add(Thread new(||
        for (i in 0..1000) {
            mutex with(||
                counter += 1   
            )
            Thread yield()
        }
    ))
}

for (t in threads) t start()
for (t in threads) t wait()

// prints counter = 10000
"counter = %d" printfln(counter)

if (counter != 10000) exit(1)
