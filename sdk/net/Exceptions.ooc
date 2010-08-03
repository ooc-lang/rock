include errno
include string

errno: extern Int
strerror: extern func(Int) -> Char*

/**
    Base exception which all networking errors extend.
 */
NetError: class extends Exception {
    init: func {
        super(String new (strerror(errno)))
    }
}

/**
    The address string provided is invalid.
 */
InvalidAddress: class extends NetError {}

/**
    A DNS error occured while performing a lookup.
 */
DNSError: class extends NetError {}

/**
    A Socket error occured.
 */
SocketError: class extends NetError {}
