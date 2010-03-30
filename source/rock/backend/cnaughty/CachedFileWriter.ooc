import io/File, text/Buffer, structs/HashMap

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
        
        if(!file exists()) {
            file write(BufferReader new(buffer))
		} else {
            thisContent := buffer toString()
            fileContent := file read()
            
            hash1 := ac_X31_hash(thisContent)
            hash2 := ac_X31_hash(fileContent)
            
			if(hash1 != hash2) {
                file write(BufferReader new(buffer))
			}
		}
        
		super()
	}
	
}
