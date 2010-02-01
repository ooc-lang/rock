
SchroedingerBox: class {
    
    cat := Cat new()
    
}

Cat: class {
    
    isAlive := true
    
}

main: func {

    box := SchroedingerBox new()
    (box cat isAlive ? "It's alive!" : "It's not :(") println()
    
}
