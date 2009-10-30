import frontend/compilers/Clang

main: func {
    compiler := Clang new()
    compiler getCommandLine() println()
}