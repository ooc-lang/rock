SourceReader: class {
	
	content: String
	index: SizeT
	
	read: func -> Char {
		value := content[index]
		index += 1
		return value
	}
	
	peek: func -> Char {
		return content[index]
	}
	
	getSlice: func (start, length: SizeT) -> String {
		return "<slice>"
	}
	
}
