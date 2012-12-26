import structs/LinkedList
import os/System
import net/[berkeley, Address, Exceptions, Socket]

/**
   Allows DNS lookups and reserve lookups
 */
DNS: class {
    /**
        Perform DNS lookup using the hostname.
        Returns information about the host that was found.
    */
    resolve: static func(hostname: String) -> HostInfo {
        return resolve(hostname, 0, 0)
    }
    resolve: static func ~filter(hostname: String, socketType: Int, socketFamily: Int) -> HostInfo {
        hints: AddrInfo
        info: AddrInfo*
        memset(hints&, 0, hints class size)
        hints ai_flags = AI_CANONNAME
        hints ai_family = socketFamily
        hints ai_socktype = socketType
        if((rv := getaddrinfo(hostname, null, hints&, info&)) != 0) {
            DNSError new(gai_strerror(rv as Int) as CString toString()) throw()
        }
        return HostInfo new(info)
    }

    /**
        Perform DNS lookup using the hostname.
        Returns the first IPAddress found for the host.
    */
    resolveOne: static func(host: String) -> IPAddress {
        info := resolve(host)
        return info addresses()[0]
    }
    resolveOne: static func ~filter(host: String, socketType: Int, socketFamily: Int) -> IPAddress {
        info := resolve(host, socketType, socketFamily)
        return info addresses()[0]
    }

    /**
        Perform a reverse DNS lookup by using the host's address.
        Returns the hostname of the specified address.
    */
    reverse: static func(ip: IPAddress) -> String {
        return reverse(SocketAddress new(ip, 0))
    }
    reverse: static func ~withSockAddr(sockaddr: SocketAddress) -> String {
        hostname := Buffer new(1024)
        if((rv := getnameinfo(sockaddr addr(), sockaddr length(), hostname toCString(), 1024, null, 0, 0)) != 0) {
            DNSError new(gai_strerror(rv as Int) as CString toString()) throw()
        }
        hostname sizeFromData()
        return hostname toString()
    }

    /**
        Returns the hostname of this system.
    */
    hostname: static func -> String {
        System hostname()
    }

    /**
        Retreive host information about this system.
    */
    localhost: static func -> HostInfo {
        return resolve(hostname())
    }
}

/**
   Information about an host, ie. its name and different addresses
 */
HostInfo: class {
    name: String
    addresses: LinkedList<IPAddress>

    /**
       Create a new HostInfo from an AddrInfo chain.

       You shouldn't have to call this function yourself, but rather
       get a HostInfo instance from calls to the DNS class.
     */
    init: func(addrinfo: AddrInfo*) {
        addresses = LinkedList<IPAddress> new()

        name = addrinfo@ ai_canonname as CString toString()
        info := addrinfo
        while(info) {
            if(info@ ai_addrlen && info@ ai_addr) {
                match(info@ ai_family) {
                    case AddressFamily IP4 =>
                        sockaddrin := info@ ai_addr as SockAddrIn*
                        addresses add(IP4Address new(sockaddrin@ sin_addr))
                }
            }
            info = info@ ai_next
        }
    }

    /**
        Returns a list of IPAddress associated with this host.
    */
    addresses: func -> LinkedList<IPAddress> {
        addresses
    }
}
