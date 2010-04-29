import net/[Socket, Address, DNS, Exceptions]
import io/[Reader, Writer]
import berkeley into socket

/**
    A stream based socket interface.
*/
StreamSocket: class extends Socket {
    remote: SocketAddress

    init: func ~addr(=remote) {
        super(remote family(), SocketType STREAM, 0)
    }
    init: func ~addrDescriptor(=remote, .descriptor) {
        super(remote family(), SocketType STREAM, 0, descriptor)
    }
    init: func ~hostAndPort(host: String, port: Int) {
        init(host, port, SocketFamily UNSPEC)
    }
    init: func ~family(host: String, port: Int, family: Int) {
        ip := DNS resolveOne(host, SocketType STREAM, family)
        init(SocketAddress new(ip, port))
    }

    connect: func {
        if(socket connect(descriptor, remote addr(), remote length()) == -1) {
            SocketError new() throw()
        }
    }

    reader: func -> StreamSocketReader {
        return StreamSocketReader new(this)
    }
    writer: func -> StreamSocketWriter {
        return StreamSocketWriter new(this)
    }

    send: func ~withLength(data: String, length: SizeT, flags: Int) -> Int {
        bytesSent := socket send(descriptor, data, length, flags)
        if(bytesSent == -1) {
            SocketError new() throw()
        }
        return bytesSent
    }
    send: func ~withFlags(data: String, flags: Int) -> Int {
        send(data, data length(), flags)
    }
    send: func(data: String) -> Int { send(data, 0) }

    sendByte: func ~withFlags(byte: Char, flags: Int) {
        if(socket send(descriptor, byte&, sizeof(Char), flags) == -1) {
            SocketError new() throw()
        }
    }
    sendByte: func(byte: Char) { sendByte(byte, 0) }

    receive: func ~withFlags(buffer: String, length: SizeT, flags: Int) -> Int {
        bytesRecv := socket recv(descriptor, buffer, length, flags)
        if(bytesRecv == -1) {
            SocketError new() throw()
        }
        return bytesRecv
    }
    receive: func(buffer: String, length: SizeT) -> Int { receive(buffer, length, 0) }

    receiveByte: func ~withFlags(flags: Int) -> Char {
        c: Char
        if(socket recv(descriptor, c&, sizeof(Char), flags) == -1) {
            SocketError new() throw()
        }
        return c
    }
    receiveByte: func -> Char { receiveByte(0) }
}

StreamSocketReader: class extends Reader {
    source: StreamSocket

    init: func(=source) { marker = 0 }

    read: func(chars: String, offset: Int, count: Int) -> SizeT {
        skip(offset - marker)
        source receive(chars, count)
    }

    read: func ~char -> Char {
        source receiveByte()
    }

    hasNext: func -> Bool {
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

    init: func(=dest) {}

    close: func { dest close() }

    write: func ~chr (chr: Char) {
        dest sendByte(chr)
    }

    write: func(chars: String, length: SizeT) -> SizeT {
        return dest send(chars, length, 0)
    }
}
