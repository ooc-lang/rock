import io/[BufferReader, BufferWriter, File], structs/HashMap

/**
   Cached file writer.

   Similar to a FileWriter, but only writes the file on closing, if
   it's different from an already-existing file, of if the target
   file doesn't eixst at all.
 */
CachedFileWriter: class extends BufferWriter {

    file: File

    init: func ~withFile(=file) {
        super()
    }

    init: func ~withPath(path: String) {
        init(File new(path))
    }

    write: func(chars: Char*, length: SizeT) -> SizeT {
        super(chars, length)
    }

    close: func {
        flushAndClose()
    }

    /**
     * :return: true if the file was really written to disk
     * (ie. if it was different from what was on-disk), false
     * if nothing was touched.
     */
    flushAndClose: func -> Bool {
        if(file exists?()) {
            thisContent := buffer toString()
            fileContent := file read()

            hash1 := ac_X31_hash(thisContent)
            hash2 := ac_X31_hash(fileContent)

            if(hash1 == hash2) {
                // same hash? don't rewrite.
                return false
            }
        }

        file write(BufferReader new(buffer))
        true
    }

}
