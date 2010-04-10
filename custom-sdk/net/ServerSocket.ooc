import net/[berkeley, Exceptions, Socket, StreamSocket, Address]

/**
    A server based socket interface.
*/
ServerSocket: class extends Socket {
    init: func {
        super(SocketFamily IP4, SocketType STREAM, 0)
    }

    /**
        Bind a local port to the socket.
    */
    bind: func(port: Int) {
        addr := SocketAddress new(IP4Address new(), port)
        bind(addr)
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
    listen: func(backlog: Int) {
        if(listen(descriptor, backlog) == -1) {
            SocketError new() throw()
        }
    }

    /**
        Accept an incoming connection and returns it.

        This method will normally block if no connection is
        available immediately.
    */
    accept: func -> StreamSocket {
        addr: SockAddr
        addrSize: UInt
        conn := accept(descriptor, addr&, addrSize&)
        if(conn == -1) {
            SocketError new() throw()
        }
        return StreamSocket new(SocketAddress newFromSock(addr&, addrSize), conn)
    }
}
