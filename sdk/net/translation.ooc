import net/[berkeley, Socket, Address]

Inet: class {

  ntop: static func (addressFamily: Int, address: Pointer,
      destination: CString, destinationSize: UInt) -> CString {

    version (!windows) {
      // use built-in!
      return inet_ntop(addressFamily, address, destination, destinationSize)
    }

    // Roll our own implementation, based on:
    // https://github.com/pkulchenko/luasocket/blob/5a58786a39bbef7ed4805821cc921f1d40f12068/src/inet.c#L512
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

    // roll our own version, based on:
    // https://github.com/diegonehab/luasocket/blob/master/src/inet.c

    hints: AddrInfo
    res: AddrInfo*
    ret := 1
    memset(hints&, 0, AddrInfo size)
    hints ai_family = addressFamily
    hints ai_flags = AI_NUMERICHOST
    if (getaddrinfo(address, null, hints&, res&) != 0) return -1
    match (addressFamily) {
      case AddressFamily IP4 =>
        in := res@ ai_addr as SockAddrIn*
        memcpy(destination, in@ sin_addr&, SockAddrIn size)
      case AddressFamily IP6 =>
        in := res@ ai_addr as SockAddrIn6*
        memcpy(destination, in@ sin6_addr&, SockAddrIn6 size)
      case =>
        ret = -1
    }

    freeaddrinfo(res)
    ret
  }

}

