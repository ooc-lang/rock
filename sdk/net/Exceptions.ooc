/**
    Base exception which all networking errors extend.
 */
NetError: class extends OSException {
    init: func { super() }
    init: func ~message (.message) { super(message) }
    init: func ~originMessage (.origin, .message) { super(origin, message) }
}

/**
    The address string provided is invalid.
 */
InvalidAddress: class extends NetError {
    init: func { super() }
    init: func ~message (.message) { super(message) }
    init: func ~originMessage (.origin, .message) { super(origin, message) }
}

/**
    A DNS error occured while performing a lookup.
 */
DNSError: class extends NetError {
    init: func { super() }
    init: func ~message (.message) { super(message) }
    init: func ~originMessage (.origin, .message) { super(origin, message) }
}

/**
    A Socket error occured.
 */
SocketError: class extends NetError {
    init: func { super() }
    init: func ~message (.message) { super(message) }
    init: func ~originMessage (.origin, .message) { super(origin, message) }
}

/**
    A Timeout occored.
 */
TimeoutError: class extends NetError {
    init: func { super() }
    init: func ~message (.message) { super(message) }
    init: func ~originMessage (.origin, .message) { super(origin, message) }
}
