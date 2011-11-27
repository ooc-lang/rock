import structs/[Bag, HashBag]

import Generator

DSL: class { // TODO: make this a singleton. or so.

    json: func (f: Func(This) -> HashBag) -> String {
        generateString(f(this))
    }

    object: func (args: ...) -> HashBag {
        object := HashBag new()
        keyFollowing := true
        key: String = null
        args each(|arg|
            match(keyFollowing) {
                case true => {
                    if(T != String) {
                        Exception new(This, "Key is not a String, but %s." format(T name)) throw()
                    } else {
                        key = arg as String
                    }
                    keyFollowing = false
                }
                case false => {
                    object put(key, arg)
                    keyFollowing = true
                }
            }
        )
        object
    }

    array: func (args: ...) -> Bag {
        bag := Bag new()
        args each(|arg|
            bag add(arg)
        )
        bag
    }
}

make: func (f: Func(DSL)) -> String {
    DSL new() json(f) // TODO: not so nice
}
