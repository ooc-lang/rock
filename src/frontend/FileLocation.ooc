FileLocation: class {
	fileName: String
	lineNumber: Int
	linePos: Int
	index: Int
	length: Int
	
	init: func(fileName: String, lineNumber: Int, linePos: Int, index: Int) {
		this(fileName, lineNumber, linePos, index, 1)
	}
	
	init: func~withLength(=fileName, =lineNumber, =linePos, =index, =length) { }
	
	getFileName: func() -> String {
		fileName
	}
	
	getLineNumber: func() -> Int {
		lineNumber
	}
	
	getLinePos: func() -> Int {
		linePos
	}
	
	getIndex: func() -> Int {
		index
	}
	
	getLength: func() -> Int {
		length
	}
	
	toString: func() -> String {
    	//" " + fileName + ":" + getLineNumber() + ":" + getLinePos()
		buffer := gc_malloc(128) as String
		sprintf(buffer, " %s:%d:%d", fileName, getLineNumber(), getLinePos())
		return buffer
	}
}
