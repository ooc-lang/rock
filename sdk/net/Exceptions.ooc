include errno
include string
import os/error

/**
    Base exception which all networking errors extend.
 */
NetError: class extends Exception {
    init: func {
        super(strerror(errno) clone())
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
