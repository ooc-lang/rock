
/**
 * Used to represent the target platform/architecture for which we're building.
 * 
 * @author Amos Wenger
 */
Target: class {
	
	/* various GNU/Linux */
	LINUX = 1,
	/* Win 9x, NT, MinGW, etc.*/
	WIN = 2,
	/* Solaris, OpenSolaris */
	SOLARIS = 3,
	/* Haiku */
	HAIKU = 4,
	/* Mac OS X */
	OSX = 5 : static const Int
	
	/**
	 * @return a guess of the platform/architecture we're building on 
	 */
	guessHost: static func -> Int {
		
        version(linux) {
            return LINUX
        }
        version(windows) {
            return WIN
        }
        version(solaris) {
            return SOLARIS
        }
        version(haiku) {
            return HAIKU
        }
        version(apple) {
            return OSX
        }
        
        fprintf(stderr, "Unknown operating system, assuming Linux...\n")
        return LINUX
		
	}
	
	/**
	 * @return true if we're on a 64bit arch
	 */
	is64: static func -> Bool {
		version(64)  { return true }
        version(!64) { return false }
	}
	
	/**
	 * @return '32' or '64' depending on the architecture
	 */
	getArch: static func -> String {
		return is64() ? "64" : "32"
	}
	
	toString: static func~defaults -> String {
		return toString(getArch())
	}
    
    toString: static func~defaultsWithArch (arch: String) -> String {
		return toString(guessHost(), arch)
	}
	
	toString: static func(target: Int, arch: String) -> String {
		
		return match(target) {
            case WIN     => "win" + arch
            case LINUX   => "linux" + arch
            case SOLARIS => "solaris" + arch
            case HAIKU   => "haiku" + arch
            case OSX     => "osx" + arch
            case         => Exception new("Invalid arch: " + target) throw(); ""
		}
		
	}
	
}
