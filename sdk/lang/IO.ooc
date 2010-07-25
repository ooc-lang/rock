include stdio

stdout, stderr, stdin: extern FStream

println: func ~withStr (str: Char*) {
	printf("%s\n", str)
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

FILE: extern cover
FStream: cover from FILE* {
	open: static func (filename, mode: const String) -> This {
        fopen(filename, mode)
    }

    close: func -> Int {
        fclose(this)
    }

    flush: func {
        fflush(this)
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
        pos := 0
        str := gc_malloc(length) as Char*

        // while it's not '\n' it means not all the line has been read
        while (true) {
            c := fgetc(this)

            if(c == '\n') {
                str[pos] = '\0'
                break
            }

            str[pos] = c
            pos += 1

            if (pos >= length) {
                // try to grow the string
                length += chunk
                tmp := gc_realloc(str, length) as String
                if(!tmp) Exception new(This, "Ran out of memory while reading a (apparently never-ending) line!") throw()
                str = tmp
            }

            if(!hasNext?()) {
                str[pos] = '\0'
                break
            }
        }

        return str as String
	}

    hasNext?: func -> Bool {
        feof(this) == 0
    }
	
	write: func ~chr (chr: Char) {
		fputc(chr, this)
	}
	
	write: func (str: String) {
		fputs(str, this)
	}
	
	write: func ~precise (str: Char*, offset: SizeT, length: SizeT) -> SizeT {
		// TODO encodings
		fwrite(str + offset, 1, length, this)
	}
	
}
