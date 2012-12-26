
import os/unistd

// Windows
version(windows) {
    // for GetSystemInfo, GetComputerNameEx.
    // 0x500 is the minimum required version, otherwise it won't link
    include windows | (_WIN32_WINNT=0x0500)
    
    SystemInfo: cover from SYSTEM_INFO {
        numberOfProcessors: extern(dwNumberOfProcessors) UInt32
    }
    GetSystemInfo: extern func (SystemInfo*)

    /* This should use values from headers, but they seem to be missing it in MinGW. Woops? */
    COMPUTER_NAME_FORMAT: enum {
        NET_BIOS = 0
        DNS_HOSTNAME
        DNS_DOMAIN
        DNS_FULLY_QUALIFIED
        PHYSICAL_NET_BIOS
        PHYSICAL_DNS_HOSTNAME
        PHYSICAL_DNS_DOMAIN
        PHYSICAL_DNS_FULLY_QUALIFIED
        MAX
    }

    GetComputerNameEx: extern func (COMPUTER_NAME_FORMAT, CString, UInt32*)
}

// Linux, OSX 10.4+
version(linux || apple) {
    include unistd // for sysconf

    sysconf: extern func (Int) -> Long
    _SC_NPROCESSORS_ONLN: extern Int
}

// for backwards compatibility, please use the namespaced version instead
numProcessors: func -> Int { System numProcessors() }

System: class {

    numProcessors: static func -> Int {
        // Source:
        // http://stackoverflow.com/questions/150355/programmatically-find-the-number-of-cores-on-a-machine
        
        version(windows) {
            sysinfo: SystemInfo
            GetSystemInfo(sysinfo&)
            return sysinfo numberOfProcessors
        }

        version(linux || apple) {
            // Linux, OSX 10.4+
            return sysconf(_SC_NPROCESSORS_ONLN)
        }
        
        1 // fallback
    }

    hostname: static func -> String {
        version (windows) {
            bufSize: UInt32 = 0
            GetComputerNameEx(COMPUTER_NAME_FORMAT DNS_HOSTNAME, null, bufSize&)
            hostname := Buffer new(bufSize)
            GetComputerNameEx(COMPUTER_NAME_FORMAT DNS_HOSTNAME, hostname data as Pointer, bufSize&)
            hostname sizeFromData()
            return hostname toString()
        }

        version (linux || apple) {
            BUF_SIZE = 255 : SizeT
            hostname := Buffer new(BUF_SIZE + 1) // we alloc one byte more so we're always zero terminated
            // according to docs, if the hostname is longer than the buffer,
            // the result will be truncated and zero termination is not guaranteed
            result := gethostname(hostname data as Pointer, BUF_SIZE)
            if(result != 0) Exception new("System host name longer than 256 characters!!") throw()
            hostname sizeFromData()
            return hostname toString()
        }

        "<unknown>" // fallback
    }

}

