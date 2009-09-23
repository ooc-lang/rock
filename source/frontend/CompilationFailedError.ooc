import FileLocation, SourceReader, text/StringBuffer

CompilationFailedError: class extends Exception {

	printed := false
	location : FileLocation

	line, cursor : String

	/**
	 * Default constructor with message
	 * @param message
	 */
	init: func ~withLocMsg (=location, message: String) {
		
		super(location == null ? message : location toString() + ": " + message)
		fillLine()
		
	}
	
	fillLine: func {
		if(location != null) {
			//try {
				reader := SourceReader getReaderFromPath(location getFileName())
				line = reader getLine(location getLineNumber())
				
				sb := StringBuffer new(line length())
				for(i in 0..(location linePos - 1)) {
					c := line charAt(i)
					if(c == '\t') {
						sb append('\t')
					} else {
						sb append(' ')
					}
				}
				for(i in 0..(location length)) sb append("^")
				cursor = sb toString()
			//} catch (IOException e) {
			//	e printStackTrace()
			//}
		}
	}

	print: func {
		//fprintf(stderr, "%s", getMessage())
		if(!printed) {
			printed = true
			//super print()
			fprintf(stderr, "%s", getMessage())
		}
	}
	
	/**
	 * @return the location
	 */
	getLocation: func -> FileLocation { location }
	
	toString: func -> String { getMessage() }
	
	getMessage: func -> String {
		if(!line) {
			//return super getMessage()
			return msg
		}
		//return "\n" + super getMessage() trim() + "\n" + line + cursor
		return "\n" + msg trim() + "\n" + line + cursor
	}
	

}
