/** Buffer/String extension for file access. splitted from main Buffer to keep
    the linkage penalty as low as possible

    @author rofl0r

*/

extend Buffer {
    /**
        reads a whole file into buffer, binary mode
    */
    fromFile: func (fileName: String) -> Bool {
        STEP_SIZE : const SizeT = 4096
        file := FStream open(fileName, "rb")
        if (!file || file error()) return false
        len := file size()
        setLength(len)
        offset :SizeT= 0
        while (len / STEP_SIZE > 0) {
            retv := file read((data + offset) as Pointer, STEP_SIZE)
            if (retv != STEP_SIZE || file error()) {
                file close()
                return false
            }
            len -= retv
            offset += retv
        }
        if (len) file read((data + offset) as Pointer, len)
        size += len
        return (file error()==0) && (file close() == 0)
    }

    toFile: func (fileName: String) -> Bool {
        toFile(fileName, false)
    }
    /**
        writes the whole data to a file in binary mode
    */
    toFile: func ~withAppend (fileName: String, doAppend: Bool) -> Bool {
        STEP_SIZE : SizeT = 4096
        file := FStream open(fileName, doAppend ? "ab" : "wb")
        if (!file || file error()) return false
        offset :SizeT = 0
        togo := size
        while (togo / STEP_SIZE > 0) {
            retv := file write ((data + offset) as String, STEP_SIZE)
            if (retv != STEP_SIZE || file error()) {
                file close()
                return false
            }
            togo -= retv
            offset  += retv
        }
        if (togo) file write((data + offset) as String, togo)
        return (file error() == 0) && (file close()==0 )
    }
}

extend String {

    toFile: func (fileName: String) -> Bool {
        _buffer toFile(fileName, false)
    }
    /**
        writes the whole data to a file in binary mode
    */
    toFile: func ~withAppend (fileName: String, doAppend: Bool) -> Bool {
        _buffer toFile(fileName, doAppend)
    }

}