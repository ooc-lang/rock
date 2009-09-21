import io/Reader
import structs/[Array, ArrayList, List]

import FileLocation

SourceReader: class extends Reader {
	
	SENSITIVE = 0, INSENSITIVE = 1 : static const Int
	
	newlineIndicies: ArrayList<Int>
	fileName: String
	content: String
	index: Int
	
	init: func(=fileName, =content) {
		index = 0
		newlineIndicies = ArrayList<Int> new()
	}
	
	peek: func() -> Char {
		content[index]
	}
	
	read: func(chars: String, offset: Int, count: Int) {
		
	}
	
	readChar: func() -> Char {
		if (index + 1 > content length())
			Exception new("Parsing ended. Parsed " + index + " chars, " + getLineNumber() + " lines total") throw()

		character := content[index]
		index += 1

		if (character == '\n') {
			if (newlineIndicies isEmpty() || newlineIndicies get(newlineIndicies lastIndex()) < index) {
				newlineIndicies add(index)
			}
		}

		return character
	}
	
	hasNext: func() -> Bool {
		return (index + 1) < content length()
	}
	
	rewind: func(offset: Int) {
		index -= index
	}
	
	mark: func() -> Int {
		marker = index
		return marker
	}
	
	reset: func(marker: Long) {
		index = marker
	}
	
	getLineNumber: func() -> Int {
		lineNumber := 0
		
		while (lineNumber < newlineIndicies size() && newlineIndicies get(lineNumber) <= index)
			lineNumber += 1
	
		return lineNumber + 1
	}
	
	getLinePos: func() -> Int {
		lineNumber := getLineNumber()
		
		if (lineNumber == 1) 
			return (index + 1)

		return index - newlineIndicies get(getLineNumber() - 2) + 1
	}
}
