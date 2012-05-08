
import io/[File, FileReader], os/[Time, Env], structs/HashMap

PreprocessorReader: class extends FileReader {
    
    init: func (path: String) {
        super(path)
    }
    
    read: func ~char -> Char {
        c := super()
                match c {
            case '\\' =>
                if(super() == '\n')
                    return super() // ignore both, it's a line continuation
                else
                    rewind(1) // whoops, nevermind, I wasn't there
        }
        c
    }
    
}

Header: class {
    
    path: String
    mark: Long
    reader: FileReader
    symbols : HashMap<String, String> { get set } 

    find: static func (name: String) -> Header {
        file := File new("/usr/local/include", name)
        if(file exists?()) return new(file path)
        
        file = File new("/usr/include", name)
        if(file exists?()) return new(file path)

        cInc := Env get("C_INCLUDE_PATH") 
        if(cInc) {
            file = File new(cInc, name)
            if(file exists?()) return new(file path)
        }

        //"Include <%s> not found!" printfln(name)
        null
    }
   
    init: func (=path) {
        symbols = HashMap<String, String> new()
        reader = PreprocessorReader new(path)
        parse()
    }

    log: func (msg: String) {
        //"HeaderParser [%s:%d] %s" printfln(path, mark, msg)
    }
    
    parse: func {
        lastId: String
        
        while(reader hasNext?()) {
            skipComments()
            if(!reader hasNext?()) {
                log("Reached end!")
                return
            }
            
            mark = reader mark()
            match (c1 := reader read()) {
                case '#' =>
                    skipWhitespace()
                    //log("Skipping directive #%s" format(reader readWhile(|c| !c whitespace?())))
                    skipLine()
                case '(' =>
                    args := readPair('(', ')') replaceAll("\n", "")
                    log("Got symbol %s with args %s" format(lastId, args))
                    symbols put(lastId, args)
                case ';' =>
                    // End of line, should probably handle stuff, skipping instead
                case '*' =>
                    // Pointer type, maybe? got '*'
                case ',' =>
                    // Multiple variable declaration?
                case '"' =>
                    reader readWhile(|c| c != '"')
                    reader read() // skip the last one
                case '{' =>
                    // just skip
                case '}' =>
                    // just skip
                case '[' =>
                    readPair('[', ']')
                    log("[%d-%d] Just read pair of '[', ']'" format(mark, reader mark()))
                case =>
                    reader rewind(1)
                    
                    id := readIdentifier()
                    if(id) {
                        lastId = id
                        match id {
                            case "struct" =>
                                skipWhitespace()
                                id2 := readIdentifier()
                                if(id2) {
                                    log("Got type 'struct %s'" format(id2))
                                }
                                
                            case =>
                                // log("Got '%s'" format(id))
                        }
                    } else if(c1 whitespace?()) {
                        // skip whitespace
                        reader read(). read()
                    } else {
                        log("Aborting on unknown char '%c', (code %d)" format(c1, c1 as Int))
                        return
                    }
            }
        }
    }

    readPair: func (beg, end: Char) -> String {
        balance := 1
        result := reader readWhile(|c|
            match c {
                case beg => balance += 1; balance > 0
                case end => balance -= 1; balance > 0
                case     => true
            }
        )
        reader read() // skip last 'end'
        result
    }
    
    readIdentifier: func -> String {
        mark := reader mark()
        c := reader read()
        
        result := match {
            case c alpha?() || c == '_' =>
                "%c%s" format(c, reader readWhile(|c| c alphaNumeric?() || c == '_'))
            case =>
                reader reset(mark)
                null
        }
        //"Just read identifier %s" printfln(result)
        result
    }
    
    skipLine: func {
        reader readWhile(|c| c != '\n')
    }
    
    skipWhitespace: func {
        reader readWhile(|c| c whitespace?())
    }
    
    skipComments: func {
        
        while(true) {
            skipWhitespace()
       
            mark := reader mark()
            match (c1 := reader read()) {
                case '/' => match(c2 := reader read()) {
                    case '/' => skipLine()
                        //"[%d-%d] skipped single-line comment!" printfln(mark, reader mark());
                        continue
                    case '*' => reader skipUntil("*/"). rewind(1)
                        //"[%d-%d] skipped multi-line comment!" printfln(mark, reader mark())
                        continue
                }
                case =>
                    //"At %d, stumbled upon %c" printfln(mark, c1)
            }
            
            reader reset(mark)
            break
        }
    }
    
}

