/**
    Base exception which all networking errors extend.
 */
NetError: class extends OSException { init : func }

/**
    The address string provided is invalid.
 */
InvalidAddress: class extends NetError { init : func }

/**
    A DNS error occured while performing a lookup.
 */
DNSError: class extends NetError { init : func }

/**
    A Socket error occured.
 */
SocketError: class extends NetError { init : func }

/**
    A Timeout occored.
 */
TimeoutError: class extends NetError { init : func }
