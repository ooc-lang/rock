import structs/[ArrayList, Bag, HashBag, Stack]
import io/[Reader, StringReader]
import text/EscapeSequence

TokenType: enum {
    None,
    String,
    Number,
    True,
    False,
    Null,
    ArrayStart,
    ArrayEnd,
    ObjectStart,
    ObjectEnd,
    Colon,
    Comma
}

Token: cover {
    type: TokenType
    value: String
}

check: func (this: Token@, type: TokenType) {
    if(this type != type) {
        ParserError new("Expected %d, got %d (%s)" format(type, this type, this value toCString())) throw()
    }
}

LexingError: class extends Exception {
    init: super func ~noOrigin
}

ParserError: class extends Exception {
    init: super func ~noOrigin
}

getToken: func (reader: Reader, token: Token*) {
    token@ type = TokenType None
    // end of string?
    if(!reader hasNext?()) {
        return
    }
    marker := reader mark()
    chr := reader read()
    // skip whitespace.
    while(chr whitespace?() || chr == 8) { // chr == 8 is a workaround. sometimes, a char 8 will appear.
        if(!reader hasNext?())
            return
        chr = reader read()
    }
    // look for token@.
    match chr {
        case 't' => {
            if(reader read() == 'r' && reader read() == 'u' && reader read() == 'e') {
                // "true"
                token@ type = TokenType True
                token@ value = "true"
                return
            } else {
                reader reset(marker)
                LexingError new("Unknown token at byte %d, (%d) '%c'" format(marker, chr as Int, chr)) throw()
            }
        }
        case 'f' => {
            if(reader read() == 'a' && reader read() == 'l' && reader read() == 's' && reader read() == 'e') {
                // "false"
                token@ type = TokenType False
                token@ value = "false"
                return
            } else {
                reader reset(marker)
                LexingError new("Unknown token at byte %d, (%d) '%c'" format(marker, chr as Int, chr)) throw()
            }
        }
        case 'n' => {
            if(reader read() == 'u' && reader read() == 'l' && reader read() == 'l') {
                token@ type = TokenType Null
                token@ value = "null"
                return
            } else {
                reader reset(marker)
                LexingError new("Unknown token at byte %d, (%d) '%c'" format(marker, chr as Int, chr)) throw()
            }
        }
        case '"' => {
            // string!
            escaped := false
            beginning := reader mark()
            while(true) {
                chr = reader read()
                if(chr == '\\' && !escaped) {
                    escaped = true
                } else {
                    if(chr == '"' && !escaped) {
                        break
                    }
                    escaped = false
                }
            }
            end := reader mark()
            reader reset(beginning)
            length := (end - beginning - 1) as SizeT
            
            buff := Buffer new(length)
            buff setLength(length)
            reader read(buff data, 0, length)
            
            // advance '"'
            reader read()
            s := String new(buff)
            token@ type = TokenType String
            token@ value = EscapeSequence unescape(s)
            return
        }
        case '[' => {
            token@ type = TokenType ArrayStart
            token@ value = "["
            return
        }
        case ']' => {
            token@ type = TokenType ArrayEnd
            token@ value = "]"
            return
        }
        case '{' => {
            token@ type = TokenType ObjectStart
            token@ value = "{"
            return
        }
        case '}' => {
            token@ type = TokenType ObjectEnd
            token@ value = "}"
            return
        }
        case ':' => {
            token@ type = TokenType Colon
            token@ value = ":"
            return
        }
        case ',' => {
            token@ type = TokenType Comma
            token@ value = ","
            return
        }
        case => {
            if(chr digit?() || chr == '-') {
                // yay number (negative or positive)
                beginning := reader mark() - 1
                while(reader hasNext?()) {
                    chr = reader read()
                    if(!chr digit?())
                        break
                }
                // frac?
                if(chr == '.') {
                    while(reader hasNext?()) {
                        chr = reader read()
                        if(!chr digit?())
                            break
                    }
                }
                // e?
                if(chr == 'e' || chr == 'E') {
                    chr = reader read()
                    if(chr == '+' || chr == '-') {
                        chr = reader read()
                    }
                    while(reader hasNext?()) {
                        chr = reader read()
                        if(!chr digit?())
                            break
                    }
                }
                end := reader mark()
                length := (end - beginning - 1) as SizeT
                s := Buffer new(length)
                s setLength(length)
                
                reader reset(beginning)
                reader read(s data, 0, length)
                token@ type = TokenType Number
                token@ value = s toString()
            } else if(chr == 0) {
                // all good
                return
            } else {
                reader reset(marker)
                LexingError new("Unknown token at byte %d, (%d) '%c'" format(marker, chr as Int, chr)) throw()
            }
        }
    }
}

ParserState: enum {
    None,
    Object1, // before key
    Object2, // after key, before colon
    Object3, // after colon, before value
    Object4, // after value, before comma (or not)
    Array1, // before value
    Array2 // after value, before comma (or not)
}

Number: class {
    value: String

    init: func (=value) {
    }
}

Parser: class {
    states: ArrayList<ParserState>
    stack: Bag
    objects, arrays: Stack<SizeT>

    init: func {
        stack = Bag new()
        states = ArrayList<ParserState> new()
        objects = Stack<SizeT> new()
        arrays = Stack<SizeT> new()
        pushState(ParserState None)
    }

    init: func ~initialFeed (reader: Reader) {
        init()
        feedAll(reader)
    }

    init: func ~initialFeedString (s: String) {
        init(StringReader new(s))
    }

    state: ParserState {
        get {
            states get(states getSize() - 1) as ParserState
        }
    }

    setState: func (state: ParserState) {
        states set(states getSize() - 1, state)
    }

    pushState: func (state: ParserState) {
        states add(state)
    }

    popState: func -> ParserState {
        states removeAt(states getSize() - 1) as ParserState
    }

    _parseSimpleValue: func (token: Token@, T: Class*) -> Pointer {
        match (token type) {
            case TokenType String => {
                value := gc_malloc(String size) as String*
                value@ = token value
                T@ = String
                return value
            }
            case TokenType Number => {
                if(token value contains?('.') || token value contains?('E') || token value contains?('e')) {
                    // store as Number (TODO!)
                    value := gc_malloc(Number size) as Number*
                    value@ = Number new(token value)
                    T@ = Number
                    return value
                } else {
                    value := gc_malloc(Int size) as Int*
                    value@ = token value toInt()
                    T@ = Int
                    return value
                }
            }
            case TokenType True => {
                value := gc_malloc(Bool size) as Bool*
                value@ = true
                T@ = Bool
                return value
            }
            case TokenType False => {
                value := gc_malloc(Bool size) as Bool*
                value@ = false
                T@ = Bool
                return value
            }
            case TokenType Null => {
                value := gc_malloc(Pointer size) as Pointer*
                value@ = null
                T@ = Pointer
                return value
            }
            case => {
                ParserError new("Unexpected token: %s" format(token value toCString())) throw()
            }
        }
        return null
    }

    push: func <T> (value: T) {
        stack add(value)
    }

    pop: func <T> (T: Class) -> T {
        stack removeAt(stack getSize() - 1, T)
    }

    rootClass: Class {
        get {
            stack getClass(0)
        }
    }

    getRoot: func <T> (T: Class) -> T {
        stack get(0, T) as T
    }

    pushSimpleValue: func (token: Token@) {
        T: Class
        valuePtr := _parseSimpleValue(token&, T&)
        cell := Cell<Pointer> new((valuePtr as Pointer*)@) // TODO: EVIL, evil hack.
        cell T = T
        stack data add(cell)
    }

    pushAnyValue: func (token: Token@) {
        match (token type) {
            case TokenType ObjectStart => {
                pushState(ParserState Object1)
                startObject()
            }
            case TokenType ArrayStart => {
                pushState(ParserState Array1)
                startArray()
            }
            case => {
                pushSimpleValue(token&)
            }
        }
    }

    startObject: func {
        push(HashBag new())
        objects push(stack getSize() - 1)
    }

    endObject: func {
        lastIndex := stack getSize() - 1
        hashbagIndex := objects pop() as SizeT
        // add everything yay.
        hashbag := stack get(hashbagIndex, HashBag)
        nextIndex := hashbagIndex + 1
        for(_ in 0..((lastIndex - hashbagIndex) / 2)) {
            key := stack removeAt(nextIndex, String) // no check should be needed.
            T: Class = stack getClass(nextIndex)
            value := stack removeAt(nextIndex, T) // TODO: ...
            hashbag put(key, value)
        }
        // done.
    }

    startArray: func {
        push(Bag new())
        arrays push(stack getSize() - 1)
    }

    endArray: func {
        lastIndex := stack getSize() - 1
        bagIndex := arrays pop() as SizeT
        // add everything yay.
        bag := stack get(bagIndex, Bag)
        nextIndex := bagIndex + 1
        for(_ in 0..(lastIndex - bagIndex)) {
            T: Class = stack getClass(nextIndex)
            value := stack removeAt(nextIndex, T) // TODO: ...
            bag add(value)
        }
        // done.
    }

    feed: func (token: Token@) {
        match state {
            case (ParserState None) => {
                pushAnyValue(token&)
                // still the None state. TODO: rly?
            }
            case (ParserState Array1) => {
                // value has to follow. or ArrayEnd (empty array)
                setState(ParserState Array2)
                if(token type == TokenType ArrayEnd) {
                    endArray()
                    popState()
                } else {
                    pushAnyValue(token&)
                }
            }
            case (ParserState Array2) => {
                // Comma or ArrayEnd has to follow
                match (token type) {
                    case (TokenType Comma) => {
                        // just set the new state.
                        setState(ParserState Array1)
                    }
                    case (TokenType ArrayEnd) => {
                        // array has come to its end.
                        endArray()
                        popState()
                    }
                }
            }
            case (ParserState Object1) => {
                // key has to follow, which has to be a string.
                // or ObjectEnd (empty object)
                setState(ParserState Object2)
                match (token type) {
                    case (TokenType ObjectEnd) => {
                        endObject()
                        popState()
                    }
                    case (TokenType String) => {
                        pushSimpleValue(token&)
                    }
                    case => {
                        ParserError new("Expected string, got %d" format(token type)) throw()
                    }
                }
            }
            case (ParserState Object2) => {
                // colon has to follow.
                setState(ParserState Object3)
                check(token&, TokenType Colon)
            }
            case (ParserState Object3) => {
                // value has to follow.
                setState(ParserState Object4)
                pushAnyValue(token&)
            }
            case (ParserState Object4) => {
                // Comma or ObjectEnd has to follow
                match (token type) {
                    case (TokenType Comma) => {
                        // just set the new state.
                        setState(ParserState Object1)
                    }
                    case (TokenType ObjectEnd) => {
                        // object has come to its end.
                        endObject()
                        popState()
                    }
                }
            }
            case => {
                ParserError new("WTF STATE? %d" format(state)) throw()
            }
        }
    }

    feedAll: func ~reader (reader: Reader) {
        token: Token
        while(true) {
            getToken(reader, token&)
            if(token type == TokenType None)
                break
            feed(token&)
        }
    }
}

printVerbose: func <T> (obj: T, indent: UInt, key: String) {
    indentStr := "    " times(indent)
    indentStr print()
    if(key != null)
        "%s => " format(key toCString()) print()
    "(%s) " format(T name toCString()) print()
    match T {
        case String => {
            obj as String print()
        }
        case Int => {
            obj as Int toString() print()
        }
        case Bool => {
            (obj as Bool ? "true" : "false") print()
        }
        case Pointer => {
            "null" print()
        }
        case Number => {
            obj as Number value print()
        }
        case HashBag => {
            "{" println()
            bag := obj as HashBag
            for(key: String in bag getKeys()) {
                U := bag getClass(key)
                printVerbose(bag get(key, U), indent + 1, key)
            }
            indentStr print()
            "}" print()
        }
        case Bag => {
            "[" println()
            bag := obj as Bag
            for(i: SizeT in 0..bag getSize()) {
                U := bag getClass(i)
                printVerbose(bag get(i, U), indent + 1, null)
            }
            indentStr print()
            "]" print()
        }
        case => {
            "<no idea>" print()
        }
    }
    "" println()
}

printVerbose: func ~lazy <T> (obj: T) {
    printVerbose(obj, 0, null)
}

parse: func <T> (reader: Reader, T: Class) -> T {
    parser := Parser new(reader)
    parser getRoot(T)
}

parse: func ~string <T> (s: String, T: Class) -> T {
    parse(StringReader new(s), T)
}

