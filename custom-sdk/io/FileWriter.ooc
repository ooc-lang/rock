import io/Writer, io/File
 
FileWriter: class extends Writer {    
    file: FStream

    init: func ~withFile (fileObject: File, append: Bool) {
        init(fileObject getPath(), append)
    }

    init: func ~withFileOverwrite (fileObject: File) {
        init(fileObject, false) 
    }
    
    init: func ~withName (fileName: String, append: Bool) {
        file = fopen(fileName, append ? "a" : "w");
        if (!file) 
            Exception new(This, "File not found: " + fileName) throw()
    }

    init: func ~withNameAndFileOverwrite(fileName: String) {
        init(fileName, false)
    }

    init: func ~withNameOverwrite (fileName: String) {
        init(fileName, false)
    }

    write: func(chars: Char*, length: SizeT) -> SizeT {
        file write(chars, 0, length)
    }
    
    write: func ~chr (chr: Char) {
        file write(chr)
    }
    
    close: func() {
        fclose(file);
    }
    
    writef: final func(fmt: String, ...) {
        ap: VaList
        va_start(ap, fmt)
        fprintf(file, fmt, ap)
        va_end(ap)
    }
    
    vwritef: final func(fmt: String, args: VaList) {
        vfprintf(file, fmt, args)
    }
}
