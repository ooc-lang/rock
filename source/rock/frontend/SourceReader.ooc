// ooc imports
import io/[Reader, FileReader, File]
import structs/[ArrayList, List]
import text/Buffer

// rock imports
import FileLocation, Locatable

SourceReader: class extends Reader {
    
    SENSITIVE = 0, INSENSITIVE = 1 : static const Int
    
    newlineIndicies: ArrayList<Int>
    fileName: String
    content: String
    index: SizeT
    mark: SizeT
    
    /**
     * Read the content of a the file at place "path"
     * @param path The path of the file to be read
     * @return a SourceReader reading from the file content
     * @throws java.io.IOException if file can't be found or opened for reading
     * (or any other I/O exception, for that matter).
     */
    getReaderFromPath: static func (path: String) -> This{
        return getReaderFromFile(File new(path));
    }

    /**
     * Read the content of a the file pointed by "file"
     * @param file The file object from which to read
     * @return a SourceReader reading from the file content
     * @throws java.io.IOException if file can't be found or opened for reading
     * (or any other I/O exception, for that matter).
     */
    getReaderFromFile: static func (file: File) -> This {
        return new(file getPath(), readToString(file))
    }
    
    /**
     * Read the content of a string
     * @param path The path this string came from. Can be an URL, a file path, etc.
     * anything descriptive, really, even "<system>" or "<copy-protected>" ^^
     * @param content
     * @return
     */
    getReaderFromText: static func (path, content: String) -> This {
        return new(path, content)
    }
    
    /**
     * Read the content of a the file pointed by "file"
     * @param file The file object from which to read
     * @return a SourceReader reading from the file content
     * @throws java.io.IOException if file can't be found or opened for reading
     * (or any other I/O exception, for that matter).
     */
    readToString: static func (file: File) -> String {
        size := file size()
        buffer : String = gc_malloc(size + 1)
        FileReader new(file) read(buffer, 0, size)
        buffer[size] = '\0';
        return buffer
    }

    /**
     * Create a new SourceReader
     * @param filePath The filepath is used in locations, for accurate
     * error messages @see SyntaxError
     * @param content The content to read from.
     */
    init: func(=fileName, =content) {
        index = 0
        mark = 0
        newlineIndicies = ArrayList<SizeT> new()
    }
    
    peek: func -> Char {
        content[index]
    }
    
    read: func(chars: String, offset, count: SizeT) {
        memcpy(chars as Char* + offset, content as Char* + index, count)
        index += count
        fprintf(stderr, "Just read %zd chars, index now = %zd\n", count, index)
    }
    
    read: func ~char -> Char {
        if (index + 1 > content length()) {
            max := 128
            msg : Char[max]
            snprintf(msg, max, "Parsing ended. Parsed %zd chars. %d lines total", index, getLineNumber())
            Exception new(msg) throw()
        }

        character := content[index]
        index += 1

        if (character == '\n') {
            if (newlineIndicies isEmpty()) {
                newlineIndicies add(index)
            }
            if (newlineIndicies get(newlineIndicies lastIndex()) < index) {
                newlineIndicies add(index)
            }
        }

        return character
    }
    
    hasNext: func -> Bool {
        return (index + 1) < content length()
    }
    
    rewind: func(offset: Int) {
        index -= offset
    }
    
    mark: func -> Int {
        marker = index
        return marker
    }
    
    reset: func~withoutMarker() { 
        index = marker
    }
    
    reset: func(marker: Long) {
        index = marker
    }
    
    getLineNumber: func -> Int {
        lineNumber := 0
        
        while (true) {
            if(lineNumber >= newlineIndicies size()) break
            if(newlineIndicies get(lineNumber) > index) break
            lineNumber += 1
        }
    
        return lineNumber + 1
    }
    
    getLinePos: func -> Int {
        lineNumber := getLineNumber()
        
        if (lineNumber == 1) 
            return (index + 1)

        return index - newlineIndicies get(getLineNumber() - 2) + 1
    }
    
    getLocation: func -> FileLocation {
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
        index := -1
        count := 0
        
        for (candidate: String in candidates) {
            if (matches(candidate, keepEnd, This SENSITIVE))
                index = count
            
            count += 1
        }
        
        return index
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
        return matches(candidate, keepEnd, This SENSITIVE)
    }
    
    matches: func~withCaseMode(candidate: String, keepEnd: Bool, caseMode: Int) -> Bool {
        mark()
        i := 0
        c, c2 : Char
        result := true
        
        while (i < candidate length()) {
            c = read()
            c2 = candidate charAt(i)
            if (c2 != c) {
                if ((caseMode == This SENSITIVE) || (c2 toLower() != c toLower())) {
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
            c := read()
            if (c isWhitespace()) {
                has = true
            } else {
                rewind(1)
                break;
            }
        }
        
        if (!skip)
            reset(mark)
            
        return has
    }

    skipLine: func {
        while(hasNext()) {
            c := read()
            if(c == '\n') {
                return
            }
        }
    }
    
    skipName: func -> Bool {
        if (hasNext()) {
            chr := read()
            if (!(chr isAlpha()) && chr != '_') {
                rewind(1)
                return false
            }
        }
            
        while(hasNext()) {
            chr := read()
            if (!(chr isAlphaNumeric()) && chr != '_' && chr != '!') {
                rewind(1)
                break
            }
        }
        return true
    }
    
    readName: func -> String {
        mark()
        ret := ""
        
        if (hasNext()) {
            chr := read();
            if (chr isAlpha() || chr == '_') {
                ret += chr
            } else {
                rewind(1)
                return ""
            }
        }
        
        while (hasNext()) {
            mark()
            chr := read()
            
            if (chr isAlphaNumeric() || chr == '_' || chr == '!') {
                rewind(1)
                break
            }
        }
        
        return ret
    }
    
    readLine: func -> String {
        readUntil('\n', true)
    }
    
    readUntil: func  ~chr (chr: Char, keepEnd: Bool) -> String {
        ret := Buffer new()
        chrRead := '\0'
        
        while(hasNext()) {
            chrRead = read()
            if(chrRead == chr) break
            ret append(chrRead)
        }
        
        if (!keepEnd) 
            reset(index - 1) // chop off the last character
        else if (chrRead != 0) 
            ret append(chr)
            
        ret toString()
    }
    
    /**
     * Read until one of the Strings in "matches" matches, and return the characters read.
     * @param readUntil The potential end delimiters
     * @param keepEnd If false, leave the position before the matching end delimiter.
     * If true, include the matching delimiter in the returned String, and leave the
     * position after.
     * @throws java.io.EOFException
     */
    readUntil: func ~strings (candidates: ArrayList<String>, keepEnd: Bool) -> String {

        sB := Buffer new()
        
        while(hasNext()) {
            for(candidate: String in candidates) {
                if(matches(candidate, keepEnd, This SENSITIVE)) {
                    if(keepEnd) {
                        sB append(candidate)
                    }
                    return sB toString()
                }
            }
            sB append(read())
        }

        return sB toString()

    }
    
    readSingleComment: func {
        readLine()
    }
    
    readMultiComment: func {
        while (!matches("*/", true, This SENSITIVE)) 
            read()
    }
    
    readMany: func(candidates, ignored: String, keepEnd: Bool) -> String {
        ret: String
        mark := mark()
        
        while (hasNext()) {
            c := read()
            
            if (candidates indexOf(c) != -1) {
                ret += c
            } else if (ignored indexOf(c) != -1) {
                // look up in the sky, and think of how lucky you are and others aren't
            } else {
                if (keepEnd) {
                    rewind(1)
                }
                break
            }
        }
        
        if (!keepEnd)
            reset(mark)

        return ret
    }
    
    readCharLiteral: func -> Char {
        mark()
        c := read()

        // TODO: finish me
        
        return c
    }
    
    readStringLiteral: func -> String {
        return readStringLiteral('"')
    }
    
    readStringLiteral: func ~withDelim (delimiter: Char) -> String {
        
        buffer := Buffer new()
        while (true) {
            mark()
            c := read()
            match c {
                case '\\' =>
                    c2 := read()
                    match c2 {
                        case '\\' => // backslash
                            buffer append('\\')
                        case '0' => // null char
                            buffer append('\0')
                        case 'n' => // newline
                            buffer append('\n')
                        case 't' => // tab
                            buffer append('\t')
                        case 'b' => // backspace
                            buffer append('\b')
                        case 'f' => // form feed
                            buffer append('\f')
                        case 'r' => // return
                            buffer append('\r')
                        case => // delimiter
                            if(c2 == delimiter) {
                                buffer append(delimiter)
                            }
                    }
                case => // TODO : wonder if newline is a syntax error in a string literal
                    if(c == delimiter) {
                        break
                    }
                    buffer append(c)
            }
        }

        return buffer toString()
        
    }
    
    /**
     * Ignore the next characters which are contained in the string 'chars'
     * @throws java.io.IOException
     */ 
    skipChars: func (chars: String) -> Bool {
        
        while(hasNext()) {
            mark := mark()
            c := read()
            if(chars indexOf(c) == -1) {
                reset(mark)
                break
            }
        }
        return true
        
    }
    
    /**
     * Get a slice of the source, specifying the start position
     * and the length of the slice.
     * @param start
     * @param length
     * @return
     */
    getSlice: func (start, length : SizeT) -> String {
        
        value := content substring(start, start + length)
        return value
        
    }
    
    /**
     * Retrieve the content of a specific line
     */
    getLine: func (lineNumber: Int) -> String {
        
        mark := mark()
        if(newlineIndicies size() > lineNumber) {
            reset(newlineIndicies get(lineNumber))
        } else {
            reset(0)
            for(i in 0..lineNumber) {
                readLine()
            }
        }
        
        line := readLine()
        reset(mark)
        return line
        
    }
    
}
