
Killable: interface {
    dyingNoise: func -> String
}

kill : func(killable: Killable) {
	"You killed it! It made a %s!" format(killable dyingNoise()) println()
}

Dog : class implements Killable {
    trap: func -> String {"HAHA it doesn't work"}
	dyingNoise : func -> String {"yowl"}
}


main : func {
	dog := Dog new()
    kill(dog)
}

