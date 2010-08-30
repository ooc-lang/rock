/**
    Base exception which all networking errors extend.
 */
NetError: class extends OSException {}

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

/**
    A Timeout occored.
 */
TimeoutError: class extends NetError {}
