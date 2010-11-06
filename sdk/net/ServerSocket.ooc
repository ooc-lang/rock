import net/[berkeley, Exceptions, Socket, StreamSocket, Address]
import text/StringTokenizer

/**
    A server based socket interface.
*/
ServerSocket: class extends Socket {

    init: func ~server {
        super(AddressFamily IP4, SocketType STREAM, 0) 
    }

    init: func ~port(port: Int) {
        init("0.0.0.0", port, false)
    }

    init: func ~ipAndPort(ip: String, port: Int) {
        init(ip, port, false)
    }

    init: func ~ipPortAndListen(ip: String, port: Int, enabled: Bool) {
        type = ipType(ip)
        super(type, SocketType STREAM, 0)
        bind(ip, port)
        if(enabled) {
            listen()
        }
    }

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

    /**
        Bind a local port to the socket.
    */
    bind: func(port: Int) {
        addr := SocketAddress new(IP4Address new(), port)
        bind(addr)
    }

    /**
        Bind a local address and port to the socket.
    */

    bind: func ~withIp(ip: String, port: Int) {
        addr: SocketAddress
        type := ipType(ip)
        if(validIp?(ip)) {
            match(type) {
                case AddressFamily IP4 =>
                    addr = _getSocketAddress(ip, port)
                case AddressFamily IP6 =>
                    addr = _getSocketAddress6(ip, port)
            }
            bind(addr)
        } else {
            InvalidAddress new("Address must be a valid IPv4 or IPv6 IP.") throw()
        }
    }

    /**
        Bind a local address to the socket.
    */
    bind: func ~withAddr(addr: SocketAddress) {
        if(bind(descriptor, addr addr(), addr length()) == -1) {
            SocketError new() throw()
        }
    }

    _getSocketAddress: func (ip: String, port: Int) -> SocketAddress {
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

    _getSocketAddress6: func (ip: String, port: Int) -> SocketAddress {
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

    /**
        Places the socket into a listening state.
    */
    listen: func(backlog: Int) {
        if(listen(descriptor, backlog) == -1) {
            SocketError new() throw()
        }
    }

    /**
        Places the socket into a listening state, with default backlog (100).
    */
    listen: func ~defaultbacklog {
        // 100 seems to be a good backlog setting to
        // not be as badly affected by SYN floods.
        // See http://tangentsoft.net/wskfaq/advanced.html#backlog for details
        listen(100)
    }

    /**
        Accept an incoming connection and returns it.

        This method will normally block if no connection is
        available immediately.
    */
    accept: func -> ReaderWriterPair {
        addr: SockAddr
        addrSize: UInt
        conn := accept(descriptor, addr&, addrSize&)
        if(conn == -1) {
            SocketError new() throw()
        }
        sock := StreamSocket new(SocketAddress newFromSock(addr&, addrSize), conn)
        return ReaderWriterPair new(sock)
    }
}

ReaderWriterPair: class { // I thought StreamSocketReaderWriterPair was a bit too long
    in: StreamSocketReader
    out: StreamSocketWriter
    sock: StreamSocket
    init: func (=sock) {
        in = sock reader()
        out = sock writer()
    }

    close: func {
        sock close()
    }
}
