include stdio

stdout, stderr, stdin: extern FStream

println: func ~withCStr (str: Char*) {
    printf("%s\n", str)
}

println: func ~withStr (str: String) {
    printf("%s\n", str toCString())
}

println: func {
    printf("\n")
}

// input/output
printf: extern func (Char*, ...) -> Int

fprintf: extern func (FStream, Char*, ...) -> Int
sprintf: extern func (Char*, Char*, ...) -> Int
snprintf: extern func (Char*, Int, Char*, ...) -> Int

vprintf: extern func (Char*, VaList) -> Int
vfprintf: extern func (FStream, Char*, VaList) -> Int
vsprintf: extern func (Char*, Char*, VaList) -> Int
vsnprintf: extern func (Char*, Int, Char*, VaList) -> Int

fread: extern func (ptr: Pointer, size: SizeT, nmemb: SizeT, stream: FStream) -> SizeT
fwrite: extern func (ptr: Pointer, size: SizeT, nmemb: SizeT, stream: FStream) -> SizeT
feof: extern func (stream: FStream) -> Int

fopen: extern func (Char*, Char*) -> FStream
fclose: extern func (file: FILE*) -> Int
fflush: extern func (file: FILE*)

fputc: extern func (Char, FStream)
fputs: extern func (Char*, FStream)

scanf: extern func (format: Char*, ...) -> Int
fscanf: extern func (stream: FStream, format: Char*, ...) -> Int
sscanf: extern func (str: Char*, format: Char*, ...) -> Int

vscanf: extern func (format: Char*, ap: VaList) -> Int
vfscanf: extern func (file: FILE*, format: Char*, ap: VaList) -> Int
vsscanf: extern func (str: Char*, format: Char*, ap: VaList) -> Int

fgets: extern func (str: Char*, length: SizeT, stream: FStream) -> Char*
fgetc: extern func (stream: FStream) -> Int

SEEK_CUR, SEEK_SET, SEEK_END: extern Int
fseek: extern func (stream: FStream, offset: Long, origin: Int ) -> Int
rewind: extern func (stream: FStream)
ftell: extern func (stream: FStream) -> Long

ferror: extern func(stream: FStream) -> Int


FILE: extern cover
FStream: cover from FILE* {
    open: static func (filename, mode: const String) -> This {
        fopen(filename, mode)
    }

    close: func -> Int {
        fclose(this)
    }

    error: func -> Int {
        ferror(this)
    }

    eof?: func -> Bool {
        feof(this) != 0
    }

    seek: func(offset: Long, origin: Int) -> Int {
        fseek(this, offset, origin)
    }

    tell: func -> Long {
        ftell(this)
    }

    flush: func {
        fflush(this)
    }

    read: func(dest: Pointer, bytesToRead: SizeT) -> SizeT {
        fread(dest, 1, bytesToRead, this)
    }

    // TODO encodings
    readChar: func -> Char {
        c : Char
        count := fread(c&, 1, 1, this)
        if(count < 1) Exception new(This, "Trying to read a char at the end of a file!") throw()
        return c
    }

    readLine: func ~defaults -> String {
        readLine(128)
    }

    readLine: func (chunk: Int) -> String {
        // 128 is a reasonable default. Most terminals are 80x25
        length := 128
        buf := Buffer new (length)

        // while it's not '\n' it means not all the line has been read
        while (true) {
            c := fgetc(this)
            if(c == '\n') break
            buf append~char((c & 0xFF) as Char)
            if(!hasNext?()) break
        }

        return buf toString()
    }

    getSize: func -> SSizeT {
        prev := tell()

        seek(0, SEEK_END)
        result := tell() as SizeT

        seek(prev, SEEK_SET)

        result
    }

    hasNext?: func -> Bool {
        feof(this) == 0
    }

    write: func ~chr (chr: Char) {
        fputc(chr, this)
    }

    write: func ~str (str: String) {
        fputs(str _buffer data, this)
    }

    write: func ~withLength (str: String, length: SizeT) -> SizeT {
        write(str _buffer data, 0, length)
    }

    write: func ~precise (str: Char*, offset: SizeT, length: SizeT) -> SizeT {
        // TODO encodings
        // TODO does offset make sense here ? it could be added to the str pointer
        fwrite(str + offset, 1, length, this)
    }

}
