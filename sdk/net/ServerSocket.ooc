import net/[berkeley, Exceptions, Socket, TCPSocket, Address]
import text/StringTokenizer

/**
    A server based socket interface.
*/
ServerSocket: class extends Socket {
    backlog: Int

    init: func ~server {
        super(AddressFamily IP4, SocketType STREAM, 0) 
    }

    /**
        Initialize the socket.

        100 seems to be a good backlog setting to not be as badly affected by SYN floods.
        See http://tangentsoft.net/wskfaq/advanced.html#backlog for details

        :param ip: The IP, for now it can NOT be a hostname (TODO: This is a bug! Fix it!)
        :param port: The port, for example 8080, or 80.
        :param bl: The backlog, defaults to 100
        :param enabled: If true, call listen(), otherwise do not
    */
    init: func ~ipPortBacklogAndListen(ip := "0.0.0.0", port: Int, bl := 100, enabled := false) {
        backlog = bl
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
    listen: func(backlog: Int) -> Bool {
        ret := listen(descriptor, backlog)
        if(ret == -1) {
            SocketError new() throw()
        }
        listening? = (ret == 0)
        listening?
    }

    /**
        Places the socket into a listening state, using backlog variable.
    */
    listen: func ~nobacklog -> Bool {
        listen(backlog)
        listening?
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
        sock := TCPSocket new(SocketAddress newFromSock(addr&, addrSize), conn)
        return ReaderWriterPair new(sock)
    }

    /**
        Run f() in a loop that calls accept()

        This method will block.
    */
    accept: func ~withClosure (f: Func(ReaderWriterPair) -> Bool) {
        if(!listening?)
            listen()

        loop(||
            conn := accept()
            ret := f(conn)
            conn close()
            conn && ret // Break out of the loop if one of conn or ret is 0 or null
        )
    }
}

ReaderWriterPair: class { // I thought TCPSocketReaderWriterPair was a bit too long
    in: TCPSocketReader
    out: TCPSocketWriter
    sock: TCPSocket
    init: func (=sock) {
        in = sock reader()
        out = sock writer()
    }

    close: func {
        sock close()
    }
}
