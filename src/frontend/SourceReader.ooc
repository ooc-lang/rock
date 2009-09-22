import io/Reader
import structs/[Array, ArrayList, List]

import FileLocation
import Locatable

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
		if (index + 1 > content length()) {
			msg : Char[128]
			sprintf(msg, "Parsing ended. Parsed %d chars. %d lines total", index, getLineNumber())
			Exception new(msg) throw()
		}

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
	
	reset: func~withoutMarker() { 
		index = marker
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
	
	getLocation: func() -> FileLocation {
		FileLocation new(fileName, getLineNumber(), getLinePos(), index)
	}
	
	getLocation: func~withLocatable(loc: Locatable) -> FileLocation {
		getLocation(loc getStart(), loc getLength())
	}
	
	getLocation: func~withStartAndLength(start: Int, length: Int) -> FileLocation {
		mark := mark()
		reset(0)
		skip(start)

		loc := getLocation()
		loc length = length
		reset(mark)
		
		return loc
	}
	
	backMatches: func(character: Char, trueIfStartPos: Bool) -> Bool {
		if (index <= 0)
			return trueIfStartPos
		
		return content charAt(index - 1) == character
	}
	
	matches: func(candidates: List<String>, keepEnd: Bool) -> Int {
		match := -1
		count := 0
		
		for (candidate: String in candidates) {
			if (matches(candidate, keepEnd, SENSITIVE))
				match = count
			
			count += 1
		}
		
		return match
	}
	
	matchesSpaced: func(candidate: String, keepEnd: Bool) -> Bool {
		mark := mark()
		result := matches(candidate, true) && hasWhitespace(false)
		
		if (keepEnd)
			reset(mark)
			
		return result
	}
	
	matchesNonident: func(candidate: String, keepEnd: Bool) -> Bool {
		mark := mark()
		result := matches(candidate, true)
		c := peek()
		
		result &= !((c == '_') || c isAlphaNumeric())
		
		if(!keepEnd)
			reset(mark)
			
		return result
	}
	
	matches: func~withString(candidate: String, keepEnd: Bool) -> Bool {
		return matches(candidate, keepEnd, SENSITIVE)
	}
	
	matches: func~withCaseMode(candidate: String, keepEnd: Bool, caseMode: Int) -> Bool {
		mark()
		i := 0
		c, c2 : Char
		result := true
		
		while (i < candidate length()) {
			c = readChar()
			c2 = candidate charAt(i)
			if (c2 != c) {
				if ((caseMode == SENSITIVE) || (c2 toLower() != c toLower())) {
					result = false
					break
				}
			}
			i += 1
		}
		
		if (!result || !keepEnd) 
			reset()
		
		return result
	}
	
	hasWhitespace: func(skip: Bool) -> Bool {
		has := false
		mark := mark()
		
		while(hasNext()) {
			c := readChar()
			if (c isWhitespace())
				has = true
			else {
				rewind(1)
				break;
			}
		}
		
		if (!skip)
			reset(mark)
			
		return has
	}
}
