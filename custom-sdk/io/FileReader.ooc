import io/Reader, io/File, text/Buffer

fopen: extern func(filename: Char*, mode: Char*) -> FILE*
fread: extern func(ptr: Pointer, size: SizeT, count: SizeT, stream: FILE*) -> SizeT
feof: extern func(stream: FILE*) -> Int
fseek: extern func(stream: FILE*, offset: Long, origin: Int) -> Int
SEEK_CUR, SEEK_SET, SEEK_END: extern Int
ftell: extern func(stream: FILE*) -> Long
 
FileReader: class extends Reader {

    file: FILE*
    
    init: func ~withFile (fileObject: File) {
        init (fileObject getPath())
    }
    
    init: func ~withName (fileName: String) {
        init (fileName, "r")
    }
        
    init: func ~withMode (fileName, mode: String) {
        file = fopen(fileName, mode)
        if (!file) 
            Exception new(This, "File not found: " + fileName) throw()
    }

    read: func(chars: String, offset: Int, count: Int) -> SizeT {
        fread(chars as Char* + offset, 1, count, file)
    }
    
    read: func ~char -> Char {
        value: Char
        fread(value&, 1, 1, file)
        return value
    }
    
    readLine: func -> String {
        sb := Buffer new(40) // let's be optimistic
        while(hasNext()) {
            c := read()
            if(c == '\n') break
            sb append(c)
        }
        return sb toString()
    }
    
    hasNext: func -> Bool {
        return !feof(file)
    }
    
    rewind: func(offset: Int) {
        fseek(file, -offset, SEEK_CUR)
    }
    
    mark: func -> Long { 
        marker = ftell(file)
        return marker
    }
    
    reset: func(marker: Long) {
        fseek(file, marker, SEEK_SET)
    }
    
    close: func {
        fclose(file)
    }
    
}
