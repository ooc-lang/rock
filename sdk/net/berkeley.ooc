include stdio
include sys/types
include sys/socket
include sys/ioctl
include sys/poll
include unistd | (__USE_BSD)
include sys/select
include arpa/inet
include netdb | (__USE_POSIX)

/**
    Low level binding to Berkeley sockets API.
*/

SockAddr: cover from struct sockaddr {
    sa_family: extern UShort    // address family, AF_xxx
    sa_data: extern Char[14]  // 14 bytes of protocol address
}

SockAddrIn: cover from struct sockaddr_in {
    sin_family: extern Short   // e.g. AF_INET
    sin_port: extern UShort     // e.g. htons(3490)
    sin_addr: extern InAddr     // see struct in_addr, below
    sin_zero: extern Char[8]  // zero this if you want to
}

InAddr: cover from struct in_addr {
    s_addr: extern ULong // load with inet_aton()
}

SockAddrIn6: cover from struct sockaddr_in6 {
    sin6_family: extern UInt16
    sin6_port: extern UInt16
    sin6_flowinfo: extern UInt32
    sin6_addr: extern In6Addr
    sin6_scope_id: extern UInt32
}

In6Addr: cover from struct in6_addr {
    s6_addr: extern UChar[16]
}

AddrInfo: cover from struct addrinfo {
    ai_flags: extern Int
    ai_family: extern Int
    ai_socktype: extern Int
    ai_protocol: extern Int

    ai_addrlen: extern UInt
    ai_canonname: extern Char*
    ai_addr: extern SockAddr*
    ai_next: extern This*
}

HostEntry: cover from struct hostent {
  h_name: extern String // official name of the host
  h_aliases: extern String* // alt names
  h_addr_type: extern Int // host type; AF_INET or AF_INET6 (IPv6)
  h_length: extern Int // length in bytes of each address
  h_addr_list: extern Char** // list of addresses for the host
}

PollFd: cover from struct pollfd {
    fd: extern Int
    events: extern Short
    revents: extern Short
}

FdSet: cover from fd_set {
    _set: extern(FD_SET) static func(fd: Int, fdset: This*)
    _isSet: extern(FD_ISSET) static func(fd: Int, fdset: This*) -> Bool
    _clr: extern(FD_CLR) static func(fd: Int, fdset: This*)
    _zero: extern(FD_ZERO) static func(fdset: This*)

    set: func(fd: Int) { _set(fd, this&) }
    isSet: func(fd: Int) -> Bool { _isSet(fd, this&) }
    clr: func(fd: Int) { _clr(fd, this&) }
    zero: func { _zero(this&) }
}

TimeVal: cover from struct timeval {
    tv_sec: extern Long
    tv_usec: extern Long
}

INADDR_ANY: extern ULong
INADDR_NONE: extern ULong
AI_CANONNAME: extern Int

socket: extern func(family, type, protocol: Int) -> Int
accept: extern func(s: Int, addr: SockAddr*, addrlen: UInt*) -> Int
bind: extern func(sockfd: Int, my_addr: SockAddr*, addrlen: UInt) -> Int
connect: extern func(sockfd: Int, serv_addr: SockAddr*, addrlen: UInt) -> Int
close: extern func(descriptor: Int) -> Int
shutdown: extern func(s: Int, how: Int) -> Int
listen: extern func(s: Int, backlog: Int) -> Int
poll: extern func(ufds: PollFd*, nfds: UInt, timeout: Int) -> Int
recv: extern func(s: Int, buf: Pointer, len: SizeT, flags: Int) -> Int
recvFrom: extern func(s: Int, buf: Pointer, len: SizeT, flags: Int, s_from: SockAddr*, fromlen: UInt) -> Int
send: extern func(s: Int, buf: Pointer, len: SizeT, flags: Int) -> Int
sendTo: extern func(s: Int, buf: Pointer, len: SizeT, flags: Int, s_to: SockAddr*, tolen: UInt) -> Int
select: extern func(n: Int, readfds: FdSet*, writefds: FdSet*, exceptfds: FdSet*, timeout: TimeVal*) -> Int
getsockopt: extern func(s: Int, level: Int, optname: Int, optval: Pointer, optlen: UInt) -> Int
setsockopt: extern func(s: Int, level: Int, optname: Int, optval: Pointer, optlen: UInt) -> Int
getaddrinfo: extern func(nodename: String, servname: String, hints: AddrInfo*, servinfo: AddrInfo**) -> Int
getnameinfo: extern func(sa: SockAddr*, salen: UInt32, host: String, hostlen: SizeT, serv: String, servlen: UInt32, flags: Int) -> Int
freeaddrinfo: extern func(ai: AddrInfo*)
gai_strerror: extern func(ecode: Int) -> const Char*
gethostname: extern func(name: String, len: SizeT) -> Int
gethostbyname: extern func(name: String) -> HostEntry*
gethostbyaddr: extern func(addr: String, len: Int, type: Int) -> HostEntry*
getpeername: extern func(s: Int, addr: SockAddr*, len: UInt) -> Int
htonl: extern func(hostlong: UInt32) -> UInt32
htons: extern func(hostshort: UInt16) -> UInt16
ntohl: extern func (netlong: UInt32) -> UInt32
ntohs: extern func (netshort: UInt16) -> UInt16
inet_ntoa: extern func(inaddr: InAddr) -> String
inet_aton: extern func(cp: String, inp: InAddr*) -> Int
inet_addr: extern func(cp: String) -> ULong
inet_ntop: extern func(af: Int, src: Pointer, dst: String, size: UInt) -> String
inet_pton: extern func(af: Int, src: String, dst: Pointer) -> Int

version(unix || apple) {
    ioctl: extern func(d: Int, request: Int, arg: Pointer) -> Int
}

FIONREAD: extern Int
