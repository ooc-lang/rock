FileLocation: class {
    
    fileName: String
    lineNumber: Int
    linePos: Int
    index: Int
    length: Int
    
    init: func(fileName: String, lineNumber: Int, linePos: Int, index: Int) {
        init(fileName, lineNumber, linePos, index, 1)
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
        max := 128
        buffer := gc_malloc(max) as String
        snprintf(buffer, max, " %s:%d:%d", fileName, getLineNumber(), getLinePos())
        return buffer
    }
    
}
