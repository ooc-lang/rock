import io/File, text/Buffer

CachedFileWriter: class extends BufferWriter {

	file: File

	init: func ~withFile(=file) {
        super()
	}
    
    init: func ~withPath(path: String) {
        init(File new(path))
    }
    
    write: func(chars: String, length: SizeT) -> SizeT {
        super(chars, length)
    }

	close: func {
        //FIXME: for some reason, file write() / file read() /
        // BufferReader / BufferWriter / others don't like
        // to play nice together.. should debug that.
        
        printf("Closing CachedFileWriter %s\n", file path)
		
		if(!file exists()) {
            printf("..doesn't exist, writing.\n")
            file write(BufferReader new(buffer))
		} else {		
            thisContent := buffer toString()
            fileContent := file read()
			if(fileContent != thisContent) {
                printf("..differs, writing.\n")
                file write(BufferReader new(buffer))
			}
		}
        
		super()
	}
	
}
