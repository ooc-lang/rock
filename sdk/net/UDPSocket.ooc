import net/[berkeley, Socket, Address, DNS, Exceptions, utilities]
import io/[Reader, Writer]

/**
    A DATAGRAM based socket interface.
 */
UDPSocket: class extends Socket {
    remote: SocketAddress

    /**
        Initialize the socket, do not bind to any IP or port.
        Can be used with 
    */
    init: func() {}

    /**
        Initialize the socket

        :param ip: The IP, for now it can NOT be a hostname (TODO: This is a bug! Fix it!)
        :param port: The port, for example 8080, or 80.
    */
    init: func ~ipPort(ip: String, port: Int) {
        super(remote family(), SocketType DATAGRAM, 0)
        type = ipType(ip)
        super(type, SocketType STREAM, 0)
        bind(ip, port)
    }

    /**
        Initialize the socket. Binds to all available IPs.

        :param port: The pot, for example 8080, or 80.
    */
    init: func ~port(port: Int) {
        /*
            Somebody tell me why ip := "0.0.0.0"
            in init(ip,port) didn't work? Oh well...
        */
        init("0.0.0.0", port)
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
       Send data through this socket
       :param data: The data to be sent
       :param length: The length of the data to be sent
       :param flags: Send flags
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withLength(data: Char*, length: SizeT, flags: Int, other: String, port: SizeT, resend: Bool) -> Int {
        ip := DNS resolveOne(other, SocketType DATAGRAM, AddressFamily IP4) // Ohai, IP4-specificness. TODO: Fix this
        remote := SocketAddress new(ip, port)
        init(remote family(), SocketType DATAGRAM, 0)

        bytesSent := sendTo(descriptor, data, length, flags, remote addr(), remote length())
        if (resend)
            while(bytesSent < length && bytesSent != -1) {
                dataSubstring := data as Char* + bytesSent
                bytesSent += sendTo(descriptor, dataSubstring, length - bytesSent, flags, remote addr(), remote length())
            }

        if(bytesSent == -1)
            SocketError new() throw()

        return bytesSent
    }

    /**
       Send a string through this socket
       :param data: The string to be sent
       :param flags: Send flags
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withFlags(data: String, flags: Int, other: String, port: SizeT, resend: Bool) -> Int {
        send(data toCString(), data size, flags, other, port, resend)
    }

    /**
       Send a string through this socket
       :param data: The string to be sent
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withResend(data: String, other: String, port: SizeT, resend: Bool) -> Int { send(data, 0, other, port, resend) }

    /**
       Send a string through this socket with resend attempted for unsent data
       :param data: The string to be sent

       :return: The number of bytes sent
     */
    send: func(data: String, other: String, port: SizeT) -> Int { send(data, other, port, true) }

    /**
       Send a byte through this socket
       :param byte: The byte to send
       :param flags: Send flags
     */
    sendByte: func ~withFlags(byte: Char, flags: Int, other: String, port: SizeT) {
        send(byte&, Char size, flags, other, port, true)
    }

    /**
       Send a byte through this socket
       :param byte: The byte to send
     */
    sendByte: func(byte: Char, other: String, port: SizeT) { sendByte(byte, 0, other, port) }

    /**
       Receive bytes from this socket
       :param buffer: Where to store the received bytes
       :param length: Size of the given buffer
       :param flags: Receive flags

       :return: Number of received bytes
     */
    receive: func ~withFlags(chars: Char*, length: SizeT, flags: Int, other: String, port: Int) -> Int {
        ip := DNS resolveOne(other, SocketType DATAGRAM, AddressFamily IP4) // Ohai, IP4-specificness. TODO: Fix this
        remote := SocketAddress new(ip, port)
        init(remote family(), SocketType DATAGRAM, 0)

        socketLength := remote length()
        bytesRecv := recvFrom(descriptor, chars, length, flags, remote addr(), socketLength&)
        if(bytesRecv == -1) {
            SocketError new() throw()
        }
        if(bytesRecv == 0) {
            connected? = false // disconnected!
        }
        return bytesRecv
    }

     /**
       Receive bytes from this socket
       :param buffer: Where to store the received bytes
       :param length: Size of the given buffer

       :return: Number of received bytes
     */
    receive: func ~withBuffer(buffer: Buffer, length: SizeT, other: String, port: Int) -> Int {
        assert (length <= buffer capacity)
        ret := receive(buffer data, length, 0, other, port)
        buffer setLength(ret)
        ret
    }

    receive: func(length: SizeT, other: String, port: Int) -> Buffer {
        buffer := Buffer new(length)
        receive(buffer, length, other, port)
        buffer
    }

    /**
       Receive a byte from this socket
       :param flags: Receive flags

       :return: The byte read
     */
    receiveByte: func ~withFlags(flags: Int, other: String, port: Int) -> Char {
        c: Char
        receive(c&, 1, 0, other, port)
        return c
    }

    /**
       Receive a byte from this socket

       :return: The byte read
     */
    receiveByte: func(other: String, port: Int) -> Char { receiveByte(0, other, port) }


//    receiveFrom:
}

