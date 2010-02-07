
KillableInterface : abstract class {
	dyingNoise : abstract func -> String
}

KillableReference : cover {
	obj : Pointer
	impl : KillableInterfaceClass
}

KillableDog : abstract class extends KillableInterface {
}

kill : func(ref : KillableReference) {
	"You killed it! It made a %s!" format(ref impl dyingNoise(ref obj)) println()
}

Dog : class {
    trap: func -> String {"HAHA it doesn't work"}
	dyingNoise : func -> String {"yowl"}
}

//operator as func(dog : Dog) -> KillableReference {
//	ref : KillableReference
//	ref obj = obj
//	ref impl = impl
//	
//	return ref
//}

main : func {
	KillableDog dyingNoise = Dog dyingNoise
	
	dog := Dog new()
	
	ref : KillableReference
	ref obj = dog
	ref impl = KillableDog
	kill(ref)
}

