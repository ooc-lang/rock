
Killable: interface {
    dyingNoise: func (n: Int) -> String
}

kill : func(killable: Killable) {
    "You killed it! It made a %s!" format(killable dyingNoise(5)) println()
}

Dog : class implements Killable {
    trap: func -> String {"HAHA it doesn't work"}
    dyingNoise : func (n: Int) -> String { printf("Yowling %d times\n", n); "yowl! " * n }
}


main : func {
    dog := Dog new()
    kill(dog)
}

