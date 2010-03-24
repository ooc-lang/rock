import structs/[ArrayList, List]
import text/StringTokenizer

/**
 * Information about a package managed by pkg-config
 * @author nddrylliog aka Amos Wenger
 */
PkgInfo: class {

	/** The name of the package, e.g. gtk+-2.0, or imlib2 */
    name: String
	
	/** The output of `pkg-config --libs name` */
	libsString: String
	
	/** The output of `pkg-config --cflags name` */
	cflagsString: String
	
	/** The C flags (including the include paths) */
    cflags := ArrayList<String> new()
	
	/** A list of all libraries needed */
    libraries := ArrayList<String> new()
	
	/** A list of all include paths */
    includePaths := ArrayList<String> new()
	
	/**
	 * Create a new Package info
	 */
    init: func (=name, =libsString, =cflagsString) {
        //printf("Created PkgInfo %s, %s, %s\n", name, libsString, cflagsString)
        
		extractTokens("-l", libsString, libraries);
		extractTokens("-I", cflagsString, includePaths);
		extractTokens("", cflagsString, cflags);
	}

	extractTokens: func (prefix, string: String, list: List<String>) {
		prefixLength := prefix length()
		
        for(token in StringTokenizer new(string, ' ')) {
			if(token startsWith(prefix)) {
				list add(token substring(prefixLength) trim(' ') trim('\n'))
			}
		}
		
	}
	
}
