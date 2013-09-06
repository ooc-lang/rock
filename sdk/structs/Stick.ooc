
/**
 * A Stick is like a BagStack, ie. it can contain any type - but
 * it provides no safety at all, ie. you have to know the types of
 * what you put in it in order to be able to push it back.
 */
Stick: class {

    base, current: Octet*
    capacity: Int // in octets

    init: func (=capacity) {
        base = gc_malloc(capacity)
        current = base
    }

    push: func <T> (element: T) {
        if((current - base + T size) as Int > capacity) {
            Exception new(This, "Pushing beyond stick limits!") throw()
        }

        memcpy(current, element, T size)
        current += T size
    }

    pop: func <T> (T: Class) -> T {
        current -= T size
        ret: T
        memcpy(ret&, current, T size)
        return ret
    }

    seek: func (index: Int) {
        current = base + index
    }

}
