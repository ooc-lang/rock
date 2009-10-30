import structs/[List, ArrayList, Array]
import Token, TokenType, SourceReader, CompilationFailedError

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

CharTuple: class {
    
    first: Char
    firstType: Octet
    
    init: func (=first, =firstType) {}
    
    handle: func (index: SizeT, c: Char, sReader: SourceReader) -> Token {
        if (c != first) return nullToken
        sReader read()
        return Token new(index, 1, firstType)
    }
    
}

CharTuple2: class extends CharTuple {
    
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

Lexer: class {
    
    debug := false
    
    setDebug: func (=debug) {}
    
    names : Array<Name> 
    chars : Array<CharTuple>
    
    init: func {
        
        namesLit := [
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
        ]
        numNames := namesLit size
        names = Array<Name> new(namesLit, numNames)
        
        charsLit : CharTuple[] = [
            CharTuple new('(', TokenType OPEN_PAREN),
            CharTuple new(')', TokenType CLOS_PAREN),
            CharTuple new('{', TokenType OPEN_BRACK),
            CharTuple new('}', TokenType CLOS_BRACK),
            CharTuple new('[', TokenType OPEN_SQUAR),
            CharTuple new(']', TokenType CLOS_SQUAR),
            CharTuple2 new('=', TokenType ASSIGN, '=', TokenType EQUALS),
            CharTuple3 new('.', TokenType DOT, '.', TokenType DOUBLE_DOT, '.', TokenType TRIPLE_DOT),
            CharTuple new(',', TokenType COMMA),
            CharTuple new('%', TokenType PERCENT),
            CharTuple new('~', TokenType TILDE),
            CharTuple2 new(':', TokenType COLON, '=', TokenType DECL_ASSIGN),
            CharTuple2 new('!', TokenType BANG, '=', TokenType NOT_EQUALS),
            //CharTuple2 new('&', TokenType AMPERSAND, '&', TokenType DOUBLE_AMPERSAND),
            CharTuple2 new('|', TokenType PIPE, '|', TokenType DOUBLE_PIPE),
            CharTuple new('?', TokenType QUEST),
            CharTuple new('#', TokenType HASH),
            CharTuple new('@', TokenType AT),
            CharTuple2 new('+', TokenType PLUS, '=', TokenType PLUS_ASSIGN),
            CharTuple2 new('*', TokenType STAR, '=', TokenType STAR_ASSIGN),
            CharTuple2 new('>', TokenType GREATERTHAN, '=', TokenType GREATERTHAN_EQUALS),
            CharTuple2 new('>', TokenType GREATERTHAN, '=', TokenType GREATERTHAN_EQUALS),
            CharTuple new('^', TokenType CARET),
        ]
        numChars := charsLit size
        chars = Array<CharTuple> new(charsLit, numChars)
        
    }
    
    parse: func (reader: SourceReader) -> List<Token> {
        
        tokens := ArrayList<Token> new()
        
        while(reader hasNext()) {
            
            reader skipChars("\t ")
            if(!reader hasNext()) {
                debugfln("Reached the end of the reader, at %s", reader getLocation() toString())
                break
            }
            
            index := reader mark()
            
            c := reader peek()
            if(c == ';' || c == '\n') {
                reader read()
                while(reader peek() == '\n' && reader hasNext()) {
                    reader read()
                }
                tokens add(Token new(index, 1, TokenType LINESEP))
                continue
            }
            
            if(c == '\\') {
                reader read()
                c2 := reader peek()
                if(c2 == '\\') {
                    reader read()
                    tokens add(Token new(index, 2, TokenType DOUBLE_BACKSLASH))
                } else if(c2 == '\n') {
                    reader read() // Just skip both of'em (line continuation)
                } else {
                    tokens add(Token new(index, 1, TokenType BACKSLASH))
                }
                continue
            }
            
            shouldContinue := false
            for(candidate: CharTuple in chars) {
                token := candidate handle(index, c, reader)
                if(!token equals(nullToken)) {
                    tokens add(token)
                    shouldContinue = true
                    break
                }
            }
            if(shouldContinue) continue

            
            if(c == '"') {
                reader read()
                // TODO: optimize. readStringLiteral actually stores it into a String, but we don't care
                //try {
                    reader readStringLiteral()
                //} catch(EOFException eof) {
                //  throw CompilationFailedError new(reader getLocation(index, 0), "Never-ending string literal (reached end of file)")
                //}
                tokens add(Token new(index + 1,
                        reader mark() - index - 2,
                        TokenType STRING_LIT))
                continue
            }
            
            if(c == '\'') {
                reader read()
                //try {
                    reader readCharLiteral()
                    tokens add(Token new(index + 1, 
                            reader mark() - index - 2,
                            TokenType CHAR_LIT))
                    continue
                //} catch(SyntaxError e) {
                //  throw CompilationFailedError new(reader getLocation(index, 0), e.getMessage())
                //}
            }
            
            if(c == '/') {
                reader read()
                c2 := reader peek()
                if(c2 == '=') {
                    reader read()
                    tokens add(Token new(index, 2, TokenType SLASH_ASSIGN))
                } else if(c2 == '/') {
                    reader readLine()
                    tokens add(Token new(index, 1, TokenType LINESEP))
                } else if(c2 == '*') {
                    reader read()
                    c3 := reader peek()
                    if(c3 == '*') {
                        reader read()
                        reader readUntil(Array<String> new(["*/"], 1), true)
                        tokens add(Token new(index, reader mark() - index, TokenType OOCDOC))
                    } else {
                        reader readUntil(Array<String> new(["*/"], 1), true)
                    }
                } else {
                    tokens add(Token new(index, 1, TokenType SLASH))
                }
                continue
            }
            
            if(c == '-') {
                reader read()
                c2 := reader peek()
                if(c2 == '>') {
                    reader read()
                    tokens add(Token new(index, 2, TokenType ARROW))
                } else if(c2 == '=') {
                    reader read()
                    tokens add(Token new(index, 2, TokenType MINUS_ASSIGN))
                } else {
                    tokens add(Token new(index, 1, TokenType MINUS))
                }
                continue
            }
            
            if(c == '<') {
                reader read()
                c2 := reader peek()
                if(c2 == '=') {
                    reader read()
                    tokens add(Token new(index, 2, TokenType LESSTHAN_EQUALS))
                } else {
                    tokens add(Token new(index, 1, TokenType LESSTHAN))
                }
                continue
            }
            
            if(c == '&') {
                // read the precious one
                reader rewind(1)
                cprev := reader read()
                reader read() // skip the '&'
                binary := false
                if(cprev == ' ') binary = true
                c2 := reader peek()
                if(c2 == '&') {
                    reader read()
                    tokens add(Token new(index, 2, TokenType DOUBLE_AMPERSAND))
                } else if(binary) {
                    tokens add(Token new(index, 1, TokenType BINARY_AND))
                } else {
                    tokens add(Token new(index, 1, TokenType AMPERSAND))
                }
                continue
            }
            
            if(c == '0') {
                reader read()
                c2 := reader peek()
                if(c2 == 'x') {
                    reader read()
                    lit := reader readMany("0123456789abcdefABCDEF", "_", true)
                    if(lit isEmpty()) {
                        CompilationFailedError new(reader getLocation(index, 0), "Empty hexadecimal number literal") throw()
                    }
                    tokens add(Token new(index + 2, reader mark() - index - 2, TokenType HEX_INT))
                    continue
                } else if(c2 == 'c') {
                    reader read()
                    lit := reader readMany("01234567", "_", true)
                    if(lit isEmpty()) {
                        CompilationFailedError new(reader getLocation(index, 0), "Empty octal number literal") throw()
                    }
                    tokens add(Token new(index + 2, reader mark() - index - 2, TokenType OCT_INT))
                    continue
                } else if(c2 == 'b') {
                    reader read()
                    lit := reader readMany("01", "_", true)
                    if(lit isEmpty()) {
                        CompilationFailedError new(reader getLocation(index, 0), "Empty binary number literal") throw()
                    }
                    tokens add(Token new(index + 2, reader mark() - index - 2, TokenType BIN_INT))
                    continue
                }
            }
            
            if(c isDigit()) {
                reader readMany("0123456789", "_", true)
                if(reader peek() == '.') {
                    reader read()
                    if(reader peek() != '.') {
                        reader readMany("0123456789", "_", true)
                        tokens add(Token new(index, reader mark() - index,
                                TokenType DEC_FLOAT))
                        continue
                    }
                    reader rewind(1)
                }
                tokens add(Token new(index, reader mark() - index,
                    TokenType DEC_INT))
                continue
            }
            
            if(reader skipName()) {
                name := reader getSlice(index, reader mark() - index)
                /*
                fprintf(stderr, "index = %d, reader mark = %d\n",
                    index, reader mark())
                */
                for(candidate: Name in names) {
                    if(candidate name equals(name)) {
                        tokens add(Token new(index, name length(), candidate tokenType))
                        shouldContinue = true
                        break
                    }
                }
                if(!shouldContinue) {
                    tokens add(Token new(index, name length(), TokenType NAME))
                    shouldContinue = true
                }
            }
            if(shouldContinue) continue
            
            max := 256
            msg : Char[max]
            snprintf(msg, max, "Unexpected input '%d'", c)
            CompilationFailedError new(reader getLocation(index, 0), msg) throw()
            
        }
        
        tokens add(Token new(reader mark(), 0, TokenType LINESEP))
        
        return tokens
        
    }
    
    debugf: final func (format: String, ...) {
        args: VaList
        if(!debug) return
        va_start(args, format)
        fprintf(stderr, "[%s] ", class name)
        vfprintf(stderr, format, args)
        va_end(args)
    }
    
    debugfln: final func (format: String, ...) {
        args: VaList
        if(!debug) return
        va_start(args, format)
        fprintf(stderr, "[%s] ", class name)
        vfprintf(stderr, format, args)
        fprintf(stderr, "\n")
        va_end(args)
    }
    
}
