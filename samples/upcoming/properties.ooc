Person: class {
    _age: UInt

    /* An advanced property. */
    age: property {
        /* `set` will be called for assignment operations. */
        set: func ~int (=_age) {
            if(_age > 120)
                "IMBA!" println()
        }
        /* You can have multiple setters. */
        set: func ~string (age: String) {
            set(age toInt())
        }
        /* But only one getter. */
        get: func -> UInt {
            _age
        }
    }

    /* A simple property that in fact only has a getter and whose value is
       computed on each new get operation. */
    imba: property {
        get: func -> Bool {
            age > 120
        }
    }

    _name: String

    /* A shortcut that creates a default getter and setter. */
    name: property(_name)
}

person := Person new()
person name = "Hello World"
person age = 5
person age = "13"
person age = 300000
"%s: %d %d" format(person name, person age, person imba) println()
person imba = true /* ERROR! */

