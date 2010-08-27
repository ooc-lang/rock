import net/[berkeley, Exceptions]

/**
    Common base for all socket types.
*/
Socket: abstract class {
    descriptor: Int
    family, type, protocol: Int

    init: func ~sock(=family, =type, =protocol) {
        descriptor = socket(family, type, protocol)
        if (descriptor == -1) {
            SocketError new("Failed to create socket") throw()
        }
    }
    init: func ~descriptor(=family, =type, =protocol, =descriptor) {}

    close: func {
        result : Int
        
        version(windows) {
            result = closesocket(descriptor)
        } else {
            result = close(descriptor)
        }
        
        if (result == -1) {
            SocketError new("Failed to close socket") throw()
        }
    }

    ioctl: func(request: Int, arg: Pointer) {
        //TODO: abstract this into version blocks to support windows
        rt := ioctl(descriptor, request, arg)
        if(rt != 0) {
            SocketError new() throw()
        }
    }

    available: func -> Int {
        result: Int
        ioctl(FIONREAD, result&)
        return result;
    }
}

SocketFamily: cover {
    UNSPEC: extern(AF_UNSPEC) static Int
    IP4: extern(AF_INET) static Int
    IP6: extern(AF_INET6) static Int
}

SocketType: cover {
    STREAM: extern(SOCK_STREAM) static Int
    DATAGRAM: extern(SOCK_DGRAM) static Int    
}

SocketMsgFlags: cover {
    OOB: extern(MSG_OOB) static Int
    DONTROUTE: extern(MSG_DONTROUTE) static Int
    DONTWAIT: extern(MSG_DONTWAIT) static Int
    NOSIGNAL: extern(MSG_NOSIGNAL) static Int
    PEEK: extern(MSG_PEEK) static Int
    WAITALL: extern(MSG_WAITALL) static Int
}

SocketShutdownOptions: cover {
    NO_MORE_RECIEVES: extern(SHUT_RD) static Int
    NO_MORE_SENDS: extern(SHUT_WR) static Int
    NO_MORE_SENDS_OR_RECIEVES: extern(SHUT_RDWR) static Int
}
