
// Linux
version(linux) {
    include unistd // for sysconf

    sysconf: extern func (Int) -> Long
    _SC_NPROCESSORS_ONLN: extern Int
}

// Windows
version(windows) {
    include windows // for GetSystemInfo
    
    SystemInfo: cover from SYSTEM_INFO {
        numberOfProcessors: extern(dwNumberOfProcessors) UInt32
    }
    GetSystemInfo: extern func (SystemInfo*)
}

numProcessors: func -> Int {
    // Source:
    // http://stackoverflow.com/questions/150355/programmatically-find-the-number-of-cores-on-a-machine
    
    version(linux) {
        return sysconf(_SC_NPROCESSORS_ONLN)
    }
    
    version(windows) {
        sysinfo: SystemInfo
        GetSystemInfo(sysinfo&)
        return sysinfo numberOfProcessors
    }
    
    "Don't know how to retrieve the number of processors of your platform, assuming 1" println()
    return 1
}

