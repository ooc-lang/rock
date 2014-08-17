
import text/Shlex
import structs/ArrayList

main: func {
    args := "rock 'is kinda' \"fun don't\" you think"
    tokens := Shlex split(args)

    check := func (index: Int, value: String) {
        if (tokens[index] != value) {
            "Fail! expected tokens[#{index}] == #{value}, but got #{tokens[index]}" println()
            exit(1)
        }
    }

    if (tokens size != 5) {
        "Fail! expected 5 tokens, got #{tokens size}" println()
        exit(1)
    }
    check(0, "rock")
    check(1, "is kinda")
    check(2, "fun don't")
    check(3, "you")
    check(4, "think")

    "Pass" println()

}
