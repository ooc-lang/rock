metaclasses
===========

Classes without an explicit super-class inherit from Object.

    Dog: class {}
    d := Dog new()
    d instanceOf(Object) // is true
    Dog inheritsFrom(Object) // is true

Every class has a meta-class. A class's meta-class inherit from
its super-class's meta-class.

E.g. if Dog extends Object, DogClass extends ObjectClass, etc.

    DogClass inheritsFrom(ObjectClass) // is true

navigating
----------

meta-classes mostly contain functions, and regular classes
contain variables and such.

You can check if you're in a meta-class with 'isMeta'. It's usually
the case if you're here because of a FunctionDecl (e.g. in resolveCall)

You can go from a class to its meta-class with getMeta(), and go back
with getNonMeta()
