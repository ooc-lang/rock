/*
    Not sure if this is the best method, but it avoids inter-dependencies
    between UDPSocket and ServerSocket.
*/

import net/[berkeley, Socket, Address, Exceptions]
import text/StringTokenizer

/**
    Is the IP provided valid as either IPv6 or IPv4? (Returns type, from AddressFamily)
*/
ipType: func(ip: String) -> Int {
    atColons := ip split(":")
    atPeriods := ip split(".")
    if(atColons size >= 2) {
        // 2 or more colons, assume IPv6
        AddressFamily IP6
    } else if(atPeriods size == 4 && atColons size == 1) {
        // No colons, 4 sections separated by 3 periods, assume IPv4
        AddressFamily IP4
    } else {
        // Who knows what was given, return UNSPEC
        AddressFamily UNSPEC
    }
}

/**
    Is the IP provided valid as either IPv6 or IPv4? (Does not return which)
*/
validIp?: func(ip: String) -> Bool {
    ipType(ip) != AddressFamily UNSPEC
}

getSocketAddress: func (ip: String, port: Int) -> SocketAddress {
    ai: InAddr
    type := ipType(ip)
    match(inet_pton(type, ip, ai&)) {
        case -1 =>
            // TODO: Check errno, it should be set to EAFNOSUPPORT
            NetError new("Invalid address family.") throw()
        case 0 =>
            NetError new("Invalid network address.") throw()
    }
    addr := SocketAddressIP4 new(ai, port)
    addr
}

getSocketAddress6: func (ip: String, port: Int) -> SocketAddress {
    ai: In6Addr
    type := ipType(ip)
    match(inet_pton(type, ip, ai&)) {
        case -1 =>
            // TODO: Check errno, it should be set to EAFNOSUPPORT
            NetError new("Invalid address family.") throw()
        case 0 =>
            NetError new("Invalid network address.") throw()
    }
    addr := SocketAddressIP6 new(ai, port)
    addr
}
