import os/Coro

mainCoro := Coro new()
mainCoro initializeMainCoro()

coro1 := Coro new()

mainCoro startCoro(coro1, ||
    coro1 switchTo(mainCoro)
    arr := ["Hello", "from", "coro1"]
    for (i in 0..arr length) {
        arr[i] println()
        coro1 switchTo(mainCoro)
    }
)

for (i in 0..3) {
    "> " print()
    mainCoro switchTo(coro1)
}

