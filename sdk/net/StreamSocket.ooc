import net/[Socket, Address, DNS, Exceptions]
import io/[Reader, Writer]
import berkeley into socket

/**
    A stream based socket interface.
 */
StreamSocket: class extends Socket {
    remote: SocketAddress

    /**
       Create a new socket to a given remote address

       :param remote: The address of the host to eventually connect to.
     */
    init: func ~addr(=remote) {
        super(remote family(), SocketType STREAM, 0)
    }

    /**
       Create a new socket to a given remote address with a specific
       file descriptor.

       :param remote: The address of the host to eventually connect to.
     */
    init: func ~addrDescriptor(=remote, .descriptor) {
        super(remote family(), SocketType STREAM, 0, descriptor)
    }

    /**
       Create a new socket to a given hostname and port number

       :param host: The hostname, for example 'localhost', or 'www.example.org'
       :param port: The port, for example 8080, or 80.
     */
    init: func ~hostAndPort(host: String, port: Int) {
        init(host, port, SocketFamily UNSPEC)
    }


    /**
       Create a new socket to a given hostname, port number and specific family

       :param host: The hostname, for example 'localhost', or 'www.example.org'
       :param port: The port, for example 8080, or 80.
       :param family: The port, for example SocketFamily IP4.
     */
    init: func ~family(host: String, port: Int, family: Int) {
        ip := DNS resolveOne(host, SocketType STREAM, family)
        init(SocketAddress new(ip, port))
    }

    /**
       Attempt to connect this socket to the remote host.

       :throws: A SocketError if something went wrong
     */
    connect: func {
        if(socket connect(descriptor, remote addr(), remote length()) == -1) {
            SocketError new() throw()
        }
    }

    /**
       :return: A reader that reads data from this socket
     */
    reader: func -> StreamSocketReader {
        return StreamSocketReader new(this)
    }

    /**
       :return: A writer that writes data to this socket
     */
    writer: func -> StreamSocketWriter {
        return StreamSocketWriter new(this)
    }

    /**
       Send data through this socket
       :param data: The data to be sent
       :param length: The length of the data to be sent
       :param flags: Send flags
       :param resend: Attempt to resend any data left unsent

       :return: The number of bytes sent
     */
    send: func ~withLength(data: String, length: SizeT, flags: Int, resend: Bool) -> Int {
        bytesSent := socket send(descriptor, data, length, flags)

        if (resend)
            while(bytesSent < length && bytesSent != -1) {
                dataSubstring := data substring(bytesSent)
                bytesSent += socket send(descriptor, dataSubstring, dataSubstring length(), flags)
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
    send: func ~withFlags(data: String, flags: Int, resend: Bool) -> Int {
        send(data, data length(), flags, resend)
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
        if(socket send(descriptor, byte&, Char size, flags) == -1) {
            SocketError new() throw()
        }
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
    receive: func ~withFlags(buffer: String, length: SizeT, flags: Int) -> Int {
        bytesRecv := socket recv(descriptor, buffer, length, flags)
        if(bytesRecv == -1) {
            SocketError new() throw()
        }
        return bytesRecv
    }

     /**
       Receive bytes from this socket
       :param buffer: Where to store the received bytes
       :param length: Size of the given buffer

       :return: Number of received bytes
     */
    receive: func(buffer: String, length: SizeT) -> Int { receive(buffer, length, 0) }

    /**
       Receive a byte from this socket
       :param flags: Receive flags

       :return: The byte read
     */
    receiveByte: func ~withFlags(flags: Int) -> Char {
        c: Char
        if(socket recv(descriptor, c&, Char size, flags) == -1) {
            SocketError new() throw()
        }
        return c
    }

    /**
       Receive a byte from this socket

       :return: The byte read
     */
    receiveByte: func -> Char { receiveByte(0) }
}

StreamSocketReader: class extends Reader {
    source: StreamSocket

    init: func ~StreamSocketReader (=source) { marker = 0 }

    close: func {
        source close()
    }

    read: func(chars: String, offset: Int, count: Int) -> SizeT {
        skip(offset - marker)
        source receive(chars, count)
    }

    read: func ~char -> Char {
        source receiveByte()
    }

    hasNext?: func -> Bool {
        source available() > 0
    }

    rewind: func(offset: Int) {
        SocketError new("Sockets do not support rewind") throw()
    }

    mark: func -> Long { marker }

    reset: func(marker: Long) {
        SocketError new("Sockets do not support reset") throw()
    }
}

StreamSocketWriter: class extends Writer {
    dest: StreamSocket

    init: func ~StreamSocketWriter (=dest) {}

    close: func { dest close() }

    write: func ~chr (chr: Char) {
        dest sendByte(chr)
    }

    write: func(chars: String, length: SizeT) -> SizeT {
        return dest send(chars, length, 0, true)
    }

    vwritef: func(fmt: String, list: VaList) {
        list2: VaList
        va_copy(list2, list)
        length := vsnprintf(null, 0, fmt, list2)
        va_end (list2)
        buffer := Buffer new ( length + 1)
        vsnprintf(buffer data, length + 1, fmt, list)
        write(buffer toString(), length)
    }
}
