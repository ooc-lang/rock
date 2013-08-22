import net/[berkeley, Socket, Address]

// For Windows, we roll our own implementation, based on:
// http://mingw-users.1079350.n2.nabble.com/IPv6-getaddrinfo-amp-inet-ntop-td5891996.html
Inet: class {

  ntop: static func (addressFamily: Int, address: Pointer,
      destination: CString, destinationSize: UInt) -> CString {

    version (!windows) {
      // use built-in!
      return inet_ntop(addressFamily, address, destination, destinationSize)
    }

    match addressFamily {
      case AddressFamily IP4 =>
        in: SockAddrIn
        memset(in&, 0, SockAddrIn size)
        in sin_family = AddressFamily IP4
        getnameinfo(in& as SockAddr*, SockAddrIn size, destination,
          destinationSize, null, 0, NI_NUMERICHOST)
        destination

      case AddressFamily IP6 =>
        in: SockAddrIn6
        memset(in&, 0, SockAddrIn6 size)
        in sin6_family = AddressFamily IP6
        getnameinfo(in& as SockAddr*, SockAddrIn6 size, destination,
          destinationSize, null, 0, NI_NUMERICHOST)
        destination

      case =>
        null
    }
    
  }

  pton: static func (addressFamily: Int, address: CString,
      destination: Pointer) -> Int {

    version (!windows) {
      // use built-in!
      return inet_pton(addressFamily, address, destination)
    }

    hints: AddrInfo
    res, ressave: AddrInfo*

    memset(hints&, 0, AddrInfo size)
    hints ai_family = AddressFamily IP4

    if (getaddrinfo(address, null, hints&, res&) != 0) {
      return -1
    }

    ressave = res

    while (res) {
      memcpy(destination, res@ ai_addr, res@ ai_addrlen)
      res = res@ ai_next
    }

    freeaddrinfo(ressave)
    return 0

  }

}

