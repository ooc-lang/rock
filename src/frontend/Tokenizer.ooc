import Token, TokenType, SourceReader

Name: cover {
	
	name: String
	tokenType: Octet
	
	new: static func (.name, .tokenType) -> This {
		this : Name
		this name = name
		this tokenType = tokenType
		return this
	}
	
}

CharTuple1: class {
	
	first: Char
	firstType: Octet
	
	init: func (=first, =firstType) {}
	
	handle: func (index: SizeT, c: Char, sReader: SourceReader) -> Token {
		if (c != first) return nullToken
		sReader read()
		return Token new(index, 1, firstType)
	}
	
}

CharTuple2: class extends CharTuple1 {
	
	second: Char
	secondType: Octet
		
	init: func ~two (=first, =firstType, =second, =secondType) {}
	
	handle: func (index: SizeT, c: Char, sReader: SourceReader) -> Token {
		if (c != first) return nullToken
		sReader read()
		if(second != sReader peek()) return Token new(index, 1, firstType)
		sReader read()
		return Token new(index, 2, secondType)
	}
	
}

CharTuple3: class extends CharTuple2 {
	
	third: Char
	thirdType: Octet
	
	init: func ~three (=first, =firstType, =second, =secondType, =third, =thirdType) {}
	
	handle: func (index: SizeT, c: Char, sReader: SourceReader) -> Token {
		if (c != first) return nullToken
		sReader read()
		if(second != sReader peek()) return Token new(index, 1, firstType)
		sReader read()
		if(third != sReader peek()) return Token new(index, 2, secondType)
		sReader read()
		return Token new(index, 3, thirdType)
	}
	
}

Tokenizer: class {
	
	names := [
		Name new("func", TokenType FUNC_KW),
		Name new("class", TokenType CLASS_KW),
		Name new("cover", TokenType COVER_KW),
		Name new("extern", TokenType EXTERN_KW),
		Name new("from", TokenType FROM_KW),
		Name new("if", TokenType IF_KW),
		Name new("else", TokenType ELSE_KW),
		Name new("for", TokenType FOR_KW),
		Name new("while", TokenType WHILE_KW),
		Name new("true", TokenType TRUE_KW),
		Name new("false", TokenType FALSE_KW),
		Name new("null", TokenType NULL_KW),
		Name new("do", TokenType DO_KW),
		Name new("switch", TokenType SWITCH_KW),
		Name new("return", TokenType RETURN_KW),
		Name new("as", TokenType AS_KW),
		Name new("const", TokenType CONST_KW),
		Name new("static", TokenType STATIC_KW),
		Name new("abstract", TokenType ABSTRACT_KW),
		Name new("import", TokenType IMPORT_KW),
		Name new("final", TokenType FINAL_KW),
		Name new("include", TokenType INCLUDE_KW),
		Name new("use", TokenType USE_KW),
		Name new("break", TokenType BREAK_KW),
		Name new("continue", TokenType CONTINUE_KW),
		Name new("fallthrough", TokenType FALLTHR_KW),
		Name new("extends", TokenType EXTENDS_KW),
		Name new("in", TokenType IN_KW),
		Name new("version", TokenType VERSION_KW),
		Name new("proto", TokenType PROTO_KW),
		Name new("inline", TokenType INLINE_KW),
		Name new("operator", TokenType OPERATOR_KW),
		//TODO I'm not sure if those three should be keywords.
		//They are remains from C and can be parsed as NAMEs
		Name new("unsigned", TokenType UNSIGNED),
		Name new("signed", TokenType SIGNED),
		Name new("long", TokenType LONG),
		Name new("union", TokenType UNION),
		Name new("struct", TokenType STRUCT),
	] as Name*

	/*
	protected static CharTuple[] chars = new CharTuple[] {
		new CharTuple('(', TokenType.OPEN_PAREN),
		new CharTuple(')', TokenType.CLOS_PAREN),
		new CharTuple('{', TokenType.OPEN_BRACK),
		new CharTuple('}', TokenType.CLOS_BRACK),
		new CharTuple('[', TokenType.OPEN_SQUAR),
		new CharTuple(']', TokenType.CLOS_SQUAR),
		new CharTuple('=', TokenType.ASSIGN, '=', TokenType.EQUALS),
		new CharTuple('.', TokenType.DOT, '.', TokenType.DOUBLE_DOT, '.', TokenType.TRIPLE_DOT),
		new CharTuple(',', TokenType.COMMA),
		new CharTuple('%', TokenType.PERCENT),
		new CharTuple('~', TokenType.TILDE),
		new CharTuple(':', TokenType.COLON, '=', TokenType.DECL_ASSIGN),
		new CharTuple('!', TokenType.BANG, '=', TokenType.NOT_EQUALS),
		//new CharTuple('&', TokenType.AMPERSAND, '&', TokenType.DOUBLE_AMPERSAND),
		new CharTuple('|', TokenType.PIPE, '|', TokenType.DOUBLE_PIPE),
		new CharTuple('?', TokenType.QUEST),
		new CharTuple('#', TokenType.HASH),
		new CharTuple('@', TokenType.AT),
		new CharTuple('+', TokenType.PLUS, '=', TokenType.PLUS_ASSIGN),
		new CharTuple('*', TokenType.STAR, '=', TokenType.STAR_ASSIGN),
		new CharTuple('>', TokenType.GREATERTHAN, '=', TokenType.GREATERTHAN_EQUALS),
		new CharTuple('>', TokenType.GREATERTHAN, '=', TokenType.GREATERTHAN_EQUALS),
		new CharTuple('^', TokenType.CARET),
	};
	
	public List<Token> parse(SourceReader reader) throws IOException {
		
		List<Token> tokens = new ArrayList<Token>();
		
		reading: while(reader.hasNext()) {
			
			reader.skipChars("\t ");
			if(!reader.hasNext()) {
				break;
			}
			
			int index = reader.mark();
			
			char c = reader.peek();
			if(c == ';' || c == '\n') {
				reader.read();
				while(reader.peek() == '\n' && reader.hasNext()) {
					reader.read();
				}
				tokens.add(new Token(index, 1, TokenType.LINESEP));
				continue;
			}
			
			if(c == '\\') {
				reader.read();
				char c2 = reader.peek();
				if(c2 == '\\') {
					reader.read();
					tokens.add(new Token(index, 2, TokenType.DOUBLE_BACKSLASH));
				} else if(c2 == '\n') {
					reader.read(); // Just skip both of'em (line continuation)
				} else {
					tokens.add(new Token(index, 1, TokenType.BACKSLASH));
				}
				continue;
			}
			
			for(CharTuple candidate: chars) {
				Token token = candidate.handle(index, c, reader);
				if(token != null) {
					tokens.add(token);
					continue reading;
				}
			}

			
			if(c == '"') {
				reader.read();
				// TODO: optimize. readStringLiteral actually stores it into a String, but we don't care
				try {
					reader.readStringLiteral();
				} catch(EOFException eof) {
					throw new CompilationFailedError(reader.getLocation(index, 0), "Never-ending string literal (reached end of file)");
				}
				tokens.add(new Token(index + 1,
						reader.mark() - index - 2,
						TokenType.STRING_LIT));
				continue;
			}
			
			if(c == '\'') {
				reader.read();
				try {
					reader.readCharLiteral();
					tokens.add(new Token(index + 1, 
							reader.mark() - index - 2,
							TokenType.CHAR_LIT));
					continue;
				} catch(SyntaxError e) {
					throw new CompilationFailedError(reader.getLocation(index, 0), e.getMessage());
				}
			}
			
			if(c == '/') {
				reader.read();
				char c2 = reader.peek();
				if(c2 == '=') {
					reader.read();
					tokens.add(new Token(index, 2, TokenType.SLASH_ASSIGN));
				} else if(c2 == '/') {
					reader.readLine();
					tokens.add(new Token(index, 1, TokenType.LINESEP));
				} else if(c2 == '*') {
					reader.read();
					char c3 = reader.peek();
					if(c3 == '*') {
						reader.read();
						reader.readUntil(new String[] {"*//*"}, true);
						tokens.add(new Token(index, reader.mark() - index, TokenType.OOCDOC));
					} else {
						reader.readUntil(new String[] {"*//*"}, true);
					}
				} else {
					tokens.add(new Token(index, 1, TokenType.SLASH));
				}
				continue;
			}
			
			if(c == '-') {
				reader.read();
				char c2 = reader.peek();
				if(c2 == '>') {
					reader.read();
					tokens.add(new Token(index, 2, TokenType.ARROW));
				} else if(c2 == '=') {
					reader.read();
					tokens.add(new Token(index, 2, TokenType.MINUS_ASSIGN));
				} else {
					tokens.add(new Token(index, 1, TokenType.MINUS));
				}
				continue;
			}
			
			if(c == '<') {
				reader.read();
				char c2 = reader.peek();
				if(c2 == '=') {
					reader.read();
					tokens.add(new Token(index, 2, TokenType.LESSTHAN_EQUALS));
				} else {
					tokens.add(new Token(index, 1, TokenType.LESSTHAN));
				}
				continue;
			}
			
			if(c == '&') {
				// read the precious one
				reader.rewind(1);
				char cprev = reader.read();
				reader.read(); // skip the '&'
				boolean binary = false;
				if(cprev == ' ') binary = true;
				char c2 = reader.peek();
				if(c2 == '&') {
					reader.read();
					tokens.add(new Token(index, 2, TokenType.DOUBLE_AMPERSAND));
				} else if(binary) {
					tokens.add(new Token(index, 1, TokenType.BINARY_AND));
				} else {
					tokens.add(new Token(index, 1, TokenType.AMPERSAND));
				}
				continue;
			}
			
			if(c == '0') {
				reader.read();
				char c2 = reader.peek();
				if(c2 == 'x') {
					reader.read();
					String lit = reader.readMany("0123456789abcdefABCDEF", "_", true);
					if(lit.isEmpty()) {
						throw new CompilationFailedError(reader.getLocation(index, 0), "Empty hexadecimal number literal");
					}
					tokens.add(new Token(index + 2, reader.mark()
							- index - 2, TokenType.HEX_INT));
					continue;
				} else if(c2 == 'c') {
					reader.read();
					String lit = reader.readMany("01234567", "_", true);
					if(lit.isEmpty()) {
						throw new CompilationFailedError(reader.getLocation(index, 0), "Empty octal number literal");
					}
					tokens.add(new Token(index + 2, reader.mark()
							- index - 2, TokenType.OCT_INT));
					continue;
				} else if(c2 == 'b') {
					reader.read();
					String lit = reader.readMany("01", "_", true);
					if(lit.isEmpty()) {
						throw new CompilationFailedError(reader.getLocation(index, 0), "Empty binary number literal");
					}
					tokens.add(new Token(index + 2, reader.mark()
							- index - 2, TokenType.BIN_INT));
					continue;
				}
			}
			
			if(Character.isDigit(c)) {
				reader.readMany("0123456789", "_", true);
				if(reader.peek() == '.') {
					reader.read();
					if(reader.peek() != '.') {
						reader.readMany("0123456789", "_", true);
						tokens.add(new Token(index, reader.mark() - index,
								TokenType.DEC_FLOAT));
						continue;
					}
					reader.rewind(1);
				}
				tokens.add(new Token(index, reader.mark() - index,
					TokenType.DEC_INT));
				continue;
			}
			
			if(reader.skipName()) {
				String name = reader.getSlice(index, reader.mark() - index);
				for(Name candidate: names) {
					if(candidate.name.equals(name)) {
						tokens.add(new Token(index, name.length(), candidate.tokenType));
						continue reading;
					}
				}
				tokens.add(new Token(index, name.length(), TokenType.NAME));
				continue reading;
			}
			throw new CompilationFailedError(reader.getLocation(index, 0), "Unexpected input.");
			
		}
		
		tokens.add(new Token(reader.mark(), 0, TokenType.LINESEP));
		
		return tokens;
	}
	*/
	
}
