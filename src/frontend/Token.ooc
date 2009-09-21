import TokenType, SourceReader

/* Will go into the load method of Token */
nullToken : Token
nullToken = Token new(0, 0, 0)

Token: cover {
	
	type: Octet
	start, length : SizeT
	
	new: static func (.start, .length, .type) -> This {
		this : This
		this start = start
		this length = length
		this type = type
		return this
	}
	
	toString: func -> String {
		return TokenType strings[type]
	}
	
	get: func(sReader: SourceReader) -> String {
		return sReader getSlice(start, length)
	}
	
	getLength: func -> SizeT {
		return length
	}
	
	getStart: func -> SizeT {
		return start
	}
	
	cloneEnclosing: func (end: Token) -> This {
		return new(start, end getEnd() - start, type)
	}
	
	getEnd: func -> SizeT {
		return start + length
	}

	isNameToken: func -> Bool {
		return type == TokenType NAME || type == TokenType CLASS_KW
	}
	
}
