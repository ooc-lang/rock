import threading/Thread
import structs/ArrayList
 
val := ThreadLocal<Int> new(42)

threads := ArrayList<Thread> new()
for (i in 1..3) {
    threads add(Thread new(||
        val set(i) 
    ))
}

for (t in threads) t start()
for (t in threads) t wait()

// prints val = 42
"val = %d" printfln(val get())

if (val get() != 42) exit(1)
