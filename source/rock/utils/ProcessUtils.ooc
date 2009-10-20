import io/[Reader, Writer]
import structs/Array

/**
 * Utilities about relaying I/O between processes launched from Java
 * and streams, writers, loggers, etc.
 * 
 * @author Amos Wenger
 */
ProcessUtils: class {

	/** The size, in bytes or chars, of a buffer used by a relay */
	BUFFER_SIZE = 4096 : static Int 
	
	// TODO: missing functionality for redirecting in-/output
}

/**
 * A stream relay pipes data from an input stream to an output stream
 * @author Amos Wenger
 */
StreamRelay: class {
	inStream: Reader
	outStream: Writer
	
	init: func(=inStream, =outStream) { }
	
	/**
	 * Update the relay
	 * @return
	 * @throws IOException 
	 */
	update: func() -> Bool {
		
		buffer := "" new(ProcessUtils BUFFER_SIZE)
		numRead: Int
		
		if ((numRead = inStream read(buffer, 0, ProcessUtils BUFFER_SIZE)) != -1) {
			outStream write(buffer, numRead)
			return true
		}
		
		return false
	}
}