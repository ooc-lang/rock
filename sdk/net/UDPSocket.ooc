import net/[berkeley, Socket, Address, DNS, Exceptions, utilities]
import io/[Reader, Writer]

/**
    A DATAGRAM based socket interface.
 */
UDPSocket: class extends Socket {
    remote: SocketAddress

    /**
        Initialize the socket. Binds to all available IPs.

        :param port: The port, for example 8080, or 80.
    */
    init: func ~port(port: Int) {
        init("0.0.0.0", port)
    }

    /**
        Initialize the socket

        :param ip: The IP, for now it can NOT be a hostname (TODO: This is a bug! Fix it!)
        :param port: The port, for example 8080, or 80.
    */
    init: func ~ipPort(host: String, port: Int) {
        // Ohai, IP4-specificness. TODO: Fix this
        ip := DNS resolveOne(host, SocketType DATAGRAM, AddressFamily IP4)
        remote = SocketAddress new(ip, port)
        super(remote family(), SocketType DATAGRAM, 0)
        type = AddressFamily IP4
    }

    /**
        Bind the socket
    */
    bind: func {
        if(bind(descriptor, remote addr(), remote length()) == -1) {
            SocketError new("Could not bind UDP socket") throw()
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
    send: func ~withLength(data: Char*, length: SizeT, flags: Int, resend: Bool) -> Int {
        bytesSent := sendTo(descriptor, data, length, flags, remote addr(), remote length())
        if (resend)
            while(bytesSent < length && bytesSent != -1) {
                dataSubstring := data as Char* + bytesSent
                bytesSent += sendTo(descriptor, dataSubstring, length - bytesSent, flags, remote addr(), remote length())
            }

        if(bytesSent == -1) {
            SocketError new("Couldn't send an UDP datagram") throw()
        }

        return bytesSent
    }

    /**
       Send a string through this socket
       :param data: The string to be sent
       :param flags: Send flags
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withFlags(data: String, flags: Int, resend: Bool) -> Int {
        send(data toCString(), data size, flags, resend)
    }

    /**
       Send a string through this socket
       :param data: The string to be sent
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withResend(data: String, resend: Bool) -> Int { send(data, 0, resend) }

    /**
       Send a string through this socket with resend attempted for unsent data
       :param data: The string to be sent

       :return: The number of bytes sent
     */
    send: func(data: String) -> Int { send(data, true) }

    /**
       Send a byte through this socket
       :param byte: The byte to send
       :param flags: Send flags
     */
    sendByte: func ~withFlags(byte: Char, flags: Int) {
        send(byte&, Char size, flags, true)
    }

    /**
       Send a byte through this socket
       :param byte: The byte to send
     */
    sendByte: func(byte: Char) { sendByte(byte, 0) }

    /**
       Receive bytes from this socket
       :param buffer: Where to store the received bytes
       :param length: Size of the given buffer
       :param flags: Receive flags

       :return: Number of received bytes
     */
    receive: func ~withFlags(chars: Char*, length: SizeT, flags: Int) -> Int {
        socketLength := remote length()
        bytesRecv := recvFrom(descriptor, chars, length, flags, remote addr(), socketLength&)
        if(bytesRecv == -1) {
            SocketError new("Error receiveing from UDP socket") throw()
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
    receive: func ~withBuffer(buffer: Buffer, length: SizeT) -> Int {
        assert (length <= buffer capacity)
        ret := receive(buffer data, length, 0)
        buffer setLength(ret)
        ret
    }

    receive: func(length: SizeT) -> Buffer {
        buffer := Buffer new(length)
        receive(buffer, length)
        buffer
    }

    /**
       Receive a byte from this socket
       :param flags: Receive flags

       :return: The byte read
     */
    receiveByte: func ~withFlags(flags: Int) -> Char {
        c: Char
        receive(c&, 1, 0)
        return c
    }

    /**
       Receive a byte from this socket

       :return: The byte read
     */
    receiveByte: func -> Char { receiveByte(0) }

//    receiveFrom:
}

