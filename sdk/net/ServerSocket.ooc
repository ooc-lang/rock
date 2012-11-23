import net/[berkeley, Exceptions, Socket, TCPSocket, Address, DNS, utilities]

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
        ip = DNS resolveOne(ip) toString()
        type = ipType(ip)
        super(type, SocketType STREAM, 0)
        bind(ip, port)
        if(enabled) {
            listen()
        }
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
                    addr = getSocketAddress(ip, port)
                case AddressFamily IP6 =>
                    addr = getSocketAddress6(ip, port)
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
    accept: func -> TCPServerReaderWriterPair {
        addr: SockAddr
        addrSize: UInt = SockAddr size
        conn := accept(descriptor, addr&, addrSize&)
        if(conn == -1) {
            SocketError new() throw()
        }
        sock := TCPSocket new(SocketAddress newFromSock(addr&, addrSize), conn)
        return TCPServerReaderWriterPair new(sock)
    }

    /**
        Run f() in a loop that calls accept()

        This method will block.
    */
    accept: func ~withClosure (f: Func(TCPServerReaderWriterPair) -> Bool) {
        if(!listening?)
            listen()

        loop(||
            conn := accept()
            ret := f(conn)
            shutdown(conn sock descriptor, SHUT_RDWR)
            conn close()
            (conn && ret) as Bool // Break out of the loop if one of conn or ret is 0 or null
        )
    }
}

/** This makes me sad, but it works and allows TCPReaderWriterPair to be
 *+ in net/TCPSocket
 */
TCPServerReaderWriterPair: class extends TCPReaderWriterPair {
    init: func (=sock) {
        super(sock)
    }
}
