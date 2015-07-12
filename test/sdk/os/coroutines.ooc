
import os/Coro

main: func {
    // no ucontext support on openbsd
    version (openbsd) {
      exit(0)
    }

    mainCoro := Coro new()
    mainCoro initializeMainCoro()
    
    letter: Char
    
    coro1 := Coro new()
    mainCoro startCoro(coro1, ||
        for (c in "LLAMACORE") {
            letter = c
            coro1 switchTo(mainCoro)
        }
        exit(0)
    )
    
    while(true) {
        "%c" printfln(letter)
        mainCoro switchTo(coro1)
    }
}

