import net/[berkeley, Socket, Exceptions]

IPAddress: abstract class {
    family: Int

    /**
        Returns true if the address is a broadcast address.

        Only IPv4 addresses can be broadcast addresses. All bits are one.
        IPv6 addresses always return false.
    */
    isBroadcast: abstract func -> Bool

    /**
        Returns true if the address is a wildcard (all zeros) address.
    */
    isWildcard: abstract func -> Bool

    /**
        Return true if the address is a global multicast address.

        IPv4 most be in the 224.0.1.0 to 238.255.255.255 range.
        IPv6 most be in the FFxF:x:x:x:x:x:x:x range.
    */
    isGlobalMulticast: abstract func -> Bool

    /**
        Returns true if the address is IPv4 compatible.

        IPv4 addresses always return true.
        IPv6 address must be in the ::x:x range (first 96 bits are zero).
    */
    isIP4Compatible: abstract func -> Bool

    /**
        Returns true if the address is an IPv4 mapped IPv6 address.

        IPv4 addresses always return true.
        IPv6 addresses must be in the ::FFFF:x:x range.
    */
    isIP4Mapped: abstract func -> Bool

    /**
        Returns true if the address is a link local unicast address.

        IPv4 addresses are in the 169.254.0.0/16 range (RFC 3927).
        IPv6 addresses have 1111 1110 10 as the first 10 bits, followed by 54 zeros.
    */
    isLinkLocal: abstract func -> Bool

    /**
        Returns true if the address is a link local multicast address.

        IPv4 addresses are in the 224.0.0.0/24 range. Note that this overlaps with the range for
        well-known multicast addresses.
    */
    isLinkLocalMulticast: abstract func -> Bool

    /**
        Returns true if the address is a loopback address.

        IPv4 address must be 127.0.0.1
        IPv6 address must be ::1
    */
    isLoopback: abstract func -> Bool

    /**
        Returns true if the address is a multicast address.

        IPv4 addresses must be in the 224.0.0.0 to 239.255.255.255 range
        (the first four bits have the value 1110).
        IPv6 addresses are in the FFxx:x:x:x:x:x:x:x range.
    */
    isMulticast: abstract func -> Bool

    /**
        Returns true if the address is a node-local multicast address.

        IPv4 does not support node-local multicast and will always return false.
        IPv6 addresses must be in the FFx1:x:x:x:x:x:x:x range.
    */
    isNodeLocalMulticast: abstract func -> Bool

    /**
        Returns true if the address is an organization-local multicast address.

        IPv4 addresses must be in the 239.192.0.0/16 range.
        IPv6 addresses must be in the FFx8:x:x:x:x:x:x:x range.
    */
    isOrgLocalMulticast: abstract func -> Bool

    /**
        Returns true if the address is a site-local unicast address.

        IPv4 addresses are in on of the 10.0.0.0/24, 192.168.0.0/16 or 172.16.0.0 to 172.31.255.255 ranges.
        IPv6 addresses have 1111 1110 11 as the first 10 bits, followed by 38 zeros.
    */
    isSiteLocal: abstract func -> Bool

    /**
        Returns true if the address is a site-local multicast address.

        IPv4 addresses are in the 239.255.0.0/16 range.
        IPv6 addresses are in the FFx5:x:x:x:x:x:x:x range.
    */
    isSiteLocalMulticast: abstract func -> Bool

    /**
        Returns true if the address is an unicast address.

        An address is unicast if it is neither a wildcard, broadcast, or multicast.
    */
    isUnicast: func -> Bool { !isWildcard() && !isBroadcast() && !isMulticast() }

    /**
        Returns true if the address is a well-known multicast address.

        IPv4 addresses are in the 224.0.0.0/8 range.
        IPv6 addresses are in the FF0x:x:x:x:x:x:x:x range.
    */
    isWellKnownMulticast: abstract func -> Bool

    /**
        Masks the IP address using the given netmask, which is usually a IPv4 subnet mask.
        Only supported for IPv4 addresses.
        The new address is (address & mask).
    */
    mask: abstract func(mask: IPAddress)

    /**
        Masks the IP address using the given netmask, which is usually a IPv4 subnet mask.
        Only supported for IPv4 addresses.

        The new address is (address & mask) | (set & mask).
    */
    mask: abstract func ~withSet(mask: IPAddress, set: IPAddress)

    /**
        Returns a string representation of the address in presentation format.
    */
    toString: abstract func -> String
}

IP4Address: class extends IPAddress {
    ai: InAddr

    init: func ~IP4Address (ipAddress: String) {
        if(ipAddress isEmpty()) {
            InvalidAddress new("Address must not be blank") throw()
        }

        family = SocketFamily IP4
        if(inet_pton(family, ipAddress, ai&) == -1) {
            InvalidAddress new("Could not parse address") throw()
        }
    }

    init: func ~wildcard {
        init("0.0.0.0")
    }

    init: func ~withAddr(addr: InAddr) {
        family = SocketFamily IP4
        memcpy(ai&, addr&, InAddr size)
    }

    isBroadcast: func -> Bool { ai s_addr == INADDR_NONE }
    isWildcard: func -> Bool { ai s_addr == INADDR_ANY }
    isGlobalMulticast: func -> Bool {
        addr := ntohl(ai s_addr)
        return addr >= 0xE0000100 && addr <= 0xEE000000
    }
    isIP4Compatible: func -> Bool { true }
    isIP4Mapped: func -> Bool { true }
    isLinkLocal: func -> Bool { (ntohl(ai s_addr) & 0xFFFF0000) == 0xA9FE0000 }
    isLinkLocalMulticast: func -> Bool { (ntohl(ai s_addr) & 0xFF000000) == 0xE0000000 }
    isLoopback: func -> Bool { ntohl(ai s_addr) == 0x7F000001 }
    isMulticast: func -> Bool { (ntohl(ai s_addr) & 0xF0000000) == 0xE0000000 }
    isNodeLocalMulticast: func -> Bool { false }
    isOrgLocalMulticast: func -> Bool { (ntohl(ai s_addr) & 0xFFFF0000) == 0xEFC00000 }
    isSiteLocal: func -> Bool {
        addr := ntohl(ai s_addr)
        return (addr & 0xFF000000) == 0x0A000000 ||
               (addr & 0xFFFF0000) == 0xC0A80000 ||
               (addr >= 0xAC100000 && addr <= 0xAC1FFFFF)
    }
    isSiteLocalMulticast: func -> Bool { (ntohl(ai s_addr) & 0xFFFF0000) == 0xEFFF0000 }
    isWellKnownMulticast: func -> Bool { (ntohl(ai s_addr) & 0xFFFFFF00) == 0xE0000000 }
    mask: func(mask: IPAddress) {
        mask(mask, IP4Address new("0.0.0.0"))
    }
    mask: func ~withSet(mask: IPAddress, set: IPAddress) {
        if(mask family != SocketFamily IP4 || set family != SocketFamily IP4) {
            NetError new("Both mask and set must be of IP4 family") throw()
        }
        maskAddr := (mask as IP4Address) ai
        setAddr := (set as IP4Address) ai

        ai s_addr = (ai s_addr & maskAddr s_addr) | (setAddr s_addr & ~maskAddr s_addr)
    }

    toString: func -> String {
        addrStr := String new(128)
        inet_ntop(family, ai&, addrStr, 128)
        return addrStr
    }
}

operator == (a1, a2: IP4Address) -> Bool {
    memcmp(a1 ai&, a2 ai&, InAddr size) == 0
}

operator != (a1, a2: IP4Address) -> Bool {
    ! (a1 == a2)
}

IP6Address: class extends IPAddress {
    ai: In6Addr

    init: func ~IP6Address (ipAddress: String) {
        if(ipAddress isEmpty()) {
            InvalidAddress new("Address must not be blank") throw()
        }

        family = SocketFamily IP6
        if(inet_pton(family, ipAddress, ai&) == -1) {
            InvalidAddress new("Could not parse address") throw()
        }
    }

    init: func ~withAddr(addr: In6Addr) {
        family = SocketFamily IP6
        memcpy(ai&, addr&, In6Addr size)
    }

    toWords: func -> UInt16* { ai& as UInt16* }

    isBroadcast: func -> Bool { false }
    isWildcard: func -> Bool {
        words := toWords()
        return words[0] == 0 && words[1] == 0 && words[2] == 0 && words[3] == 0 &&
            words[4] == 0 && words[5] == 0 && words[6] == 0 && words[7] == 0
    }
    isGlobalMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFEF) == 0xFF0F
    }
    isIP4Compatible: func -> Bool {
        words := toWords()
        return words[0] == 0 && words[1] == 0 && words[2] == 0 && words[3] == 0 &&
            words[4] == 0 && words[5] == 0
    }
    isIP4Mapped: func -> Bool {
        words := toWords()
        return words[0] == 0 && words[1] == 0 && words[2] == 0 && words[3] == 0 &&
            words[4] == 0 && words[5] == 0xFFFF
    }
    isLinkLocal: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFE0) == 0xFE80
    }
    isLinkLocalMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFEF) == 0xFF02
    }
    isLoopback: func -> Bool {
        words := toWords()
        return words[0] == 0 && words[1] == 0 && words[2] == 0 && words[3] == 0 &&
            words[4] == 0 && words[5] == 0 && words[6] == 0 && words[7] == 1
    }
    isMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFE0) == 0xFF00
    }
    isNodeLocalMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFEF) == 0xFF01
    }
    isOrgLocalMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFEF) == 0xFF08
    }
    isSiteLocal: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFE0) == 0xFEC0
    }
    isSiteLocalMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFEF) == 0xFF05
    }
    isWellKnownMulticast: func -> Bool {
        words := toWords()
        return (words[0] & 0xFFF0) == 0xFF00
    }
    mask: func(mask: IPAddress) {
        mask(mask, null)
    }
    mask: func ~withSet(mask: IPAddress, set: IPAddress) {
        NetError new("Mask is only supported with IP4 addresses") throw()
    }

    toString: func -> String {
        addrStr := String new(128)
        inet_ntop(family, ai&, addrStr, 128)
        return addrStr
    }
}

operator == (a1, a2: IP6Address) -> Bool {
    memcmp(a1 ai&, a2 ai&, In6Addr size) == 0
}

operator != (a1, a2: IP6Address) -> Bool {
    ! (a1 == a2)
}

operator == (a1, a2: IPAddress) -> Bool {
    if (a1 family != a2 family)
        return false

    if (a1 family == SocketFamily IP4)
        return (a1 as IP4Address) == (a2 as IP4Address)
    else
        return (a1 as IP6Address) == (a2 as IP6Address)
}

operator != (a1, a2: IPAddress) -> Bool {
    ! (a1 == a2)
}

SocketAddress: abstract class {
    new: static func(host: IPAddress, port: Int) -> This {
        nPort: Int = htons(port)

        if(host family == SocketFamily IP4) {
            ip4Host := host as IP4Address
            return SocketAddressIP4 new(ip4Host ai, nPort)
        }
        else if(host family == SocketFamily IP6) {
            ip6Host := host as IP6Address
            return SocketAddressIP6 new(ip6Host ai, nPort)
        }
        else {
            NetError new("Unsupported IP Address type!") throw()
            return null
        }
    }

    newFromSock: static func(addr: SockAddr*, len: UInt) -> This {
        if(len == SockAddrIn size) {
            return SocketAddressIP4 new(addr as SockAddrIn*)
        }
        else if(len == SockAddrIn6 size) {
            return SocketAddressIP6 new(addr as SockAddrIn6*)
        }
        else {
            NetError new("Unknown SockAddr type!") throw()
            return null
        }
    }

    family: abstract func -> Int
    host: abstract func -> IPAddress
    port: abstract func -> Int

    addr: abstract func -> SockAddr*
    length: abstract func -> UInt32

    toString: func -> String {
        "[%s]:%d" format(host() toString(), port())
    }
}

operator == (sa1, sa2: SocketAddress) -> Bool {
    (sa1 family() == sa2 family()) && (memcmp(sa1 addr(), sa2 addr(), sa1 length()) == 0)
}

operator != (sa1, sa2: SocketAddress) -> Bool {
    ! (sa1 == sa2)
}

SocketAddressIP4: class extends SocketAddress {
    sa: SockAddrIn

    init: func ~SocketAddressIP4 (addr: InAddr, port: Int) {
        memset(sa&, 0, SockAddrIn size)
        sa sin_family = SocketFamily IP4
        memcpy(sa sin_addr&, addr&, InAddr size)
        sa sin_port = port
    }
    init: func ~sock(sockAddr: SockAddrIn*) {
        memcpy(sa&, sockAddr, SockAddrIn size)
    }

    family: func -> Int { sa sin_family }
    host: func -> IPAddress { IP4Address new(sa sin_addr) }
    port: func -> Int { ntohs(sa sin_port) }

    addr: func -> SockAddr* { (sa&) as SockAddr* }
    length: func -> UInt32 { SockAddrIn size }
}

SocketAddressIP6: class extends SocketAddress {
    sa: SockAddrIn6

    init: func ~SocketAddressIP6 (addr: In6Addr, port: Int) {
        memset(sa&, 0, SockAddrIn6 size)
        sa sin6_family = SocketFamily IP6
        memcpy(sa sin6_addr&, addr&, In6Addr size)
        sa sin6_port = port
    }
    init: func ~sock6(sockAddr: SockAddrIn6*) {
        memcpy(sa&, sockAddr, SockAddrIn6 size)
    }

    family: func -> Int { sa sin6_family }
    host: func -> IPAddress { IP6Address new(sa sin6_addr) }
    port: func -> Int { ntohs(sa sin6_port) }

    addr: func -> SockAddr* { (sa&) as SockAddr* }
    length: func -> UInt32 { SockAddrIn6 size }
}
