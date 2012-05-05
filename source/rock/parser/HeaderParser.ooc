
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
    fR: FileReader
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

        "Include <%s> not found!" printfln(name)
        null
    }
   
    init: func (=path) {
        symbols = HashMap<String, String> new()
        fR = PreprocessorReader new(path)
        parse()
    }
    
    parse: func {
        lastId: String
        
        while(fR hasNext?()) {
            skipComments()
            if(!fR hasNext?()) return
            
            mark := fR mark()
            match (c1 := fR read()) {
                case '#' =>
                    skipWhitespace()
                    //"[%d] Skipping directive #%s" printfln(mark, fR readWhile(|c| !c whitespace?()))
                    skipLine()
                case '(' =>
                    parenCount := 1
                    call := fR readWhile(|c|
                        match c {
                            case '(' => parenCount += 1; true
                            case ')' => parenCount -= 1; true
                            case     => parenCount > 0
                        }
                    ) replaceAll("\n", "")
                    //"[%d] Got symbol %s(%s" printfln(mark, lastId, call)
                    symbols put(lastId, call)
                case ';' =>
                    //"[%d] End of line, should probably handle stuff, just skipping for now!" printfln(mark)
                case '*' =>
                    //"[%d] Pointer type, maybe? got *" printfln(mark)
                case '"' =>
                    // TODO: escapes
                    fR readWhile(|c| c != '"')
                    fR read() // skip the last one
                case '{' =>
                    // TODO: strings and stuff
                    parenCount := 1
                    call := fR readWhile(|c|
                        match c {
                            case '{' => parenCount += 1; true
                            case '}' => parenCount -= 1; true
                            case     => parenCount > 0
                        }
                    ) replaceAll("\n", "")
                case =>
                    fR rewind(1)
                    
                    id := readIdentifier()
                    if(id) {
                        lastId = id
                        match id {
                            case "struct" =>
                                skipWhitespace()
                                id2 := readIdentifier()
                                if(!id2) {
                                    "[%s:%d] Aborting on unfinished struct" printfln(path, mark)
                                    return
                                }
                                //"[%d] Got type 'struct %s'" printfln(mark, id2)
                            case =>
                                //"[%d] Got '%s'" printfln(mark, id)
                        }
                    } else if(c1 whitespace?()) {
                        // skip
                        //"[%d] Skipping whitespace" printfln(fR mark())
                        fR read(). read()
                    } else {
                        "[%s:%d] Aborting on unknown char '%c', (code %d)" printfln(path, mark, c1, c1 as Int)
                        return
                    }
            }
        }
    }
    
    readIdentifier: func -> String {
        mark := fR mark()
        c := fR read()
        
        result := match {
            case c alpha?() || c == '_' =>
                "%c%s" format(c, fR readWhile(|c| c alphaNumeric?() || c == '_'))
            case =>
                fR reset(mark)
                null
        }
        //"Just read identifier %s" printfln(result)
        result
    }
    
    skipLine: func {
        fR readWhile(|c| c != '\n')
    }
    
    skipWhitespace: func {
        fR readWhile(|c| c whitespace?())
    }
    
    skipComments: func {
        
        while(true) {
            skipWhitespace()
       
            mark := fR mark()
            match (c1 := fR read()) {
                case '/' => match(c2 := fR read()) {
                    case '/' => skipLine()
                        //"[%d] skipped single-line comment!" printfln(mark); 
                        continue
                    case '*' => fR skipUntil("*/"). rewind(1)
                        //"[%d] skipped multi-line comment!"  printfln(mark);
                        continue
                }
                case =>
                    //"At %d, stumbled upon %c" printfln(mark, c1)
            }
            
            fR reset(mark)
            break
        }
    }
    
}

