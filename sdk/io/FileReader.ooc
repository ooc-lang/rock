import io/Reader, io/File

/**
 * Implement the Reader interface for file input
 * 
 * By default, files are opened in binary mode. If you want to open
 * them in text mode, use the new~withMode variant, but beware: on 
 * mingw, rewind()/mark() won't work correctly.
 * @author Amos Wenger (nddrylliog)
 */
FileReader: class extends Reader {

    fileName := "<stream>"
    
    /** The underlying file descriptor */
    file: FStream

	/**
	 * Open a file for reading in binary mode, given a `File` object.
	 */
    init: func ~withFile (fileObject: File) {
        init(fileObject getPath())
    }

	/**
	 * Open a file for reading in binary mode, given its name.
	 */
    init: func ~withName (fileName: String) {
		// mingw fseek/ftell are *really* unreliable with text mode
		// if for some weird reason you need to open in text mode, use
		// FileReader new(fileName, "rt")
        init(fileName, "rb")
    }

	/**
	 * Open a file for reading, given its name and the mode in which to open it.
	 * 
	 * "r" = for reading
	 * "w" = for writing
	 * "r+" = for reading and writing
	 * 
	 * suffix "a" = appending
	 * suffix "b" = binary mode
	 * suffix "t" = text mode (warning: rewind/mark are unreliable in text mode under mingw32)
	 */
    init: func ~withMode (fileName, mode: String) {
        this fileName = fileName
        file = FStream open(fileName, mode)
        if (!file)
            Exception new(This, "Couldn't open " + fileName + " for reading.") throw()
    }

	/**
	 * Read at most `bytesToRead` bytes and writes them at offset `offset` into `dest`
	 * 
	 * @param dest Pointer to a memory block large enough to hold up to
	 * `bytesToRead` bytes.
	 * @param offset Offset from `dest` where to actually write the bytes.
	 * @param bytesToRead Maximum number of bytes to be read. It might
	 * read exactly `bytesToRead` bytes, or less, or even none.
	 * 
	 * @return The number of bytes read.
	 */
    read: func(buffer: Pointer, offset: Int, count: SizeT) -> SizeT {
		file read((buffer as Char*) + offset, count)
    }

	/**
	 * @return a single char read from this file.
	 */
    read: func ~char -> Char {
		file readChar()
    }

	/**
	 * @return true if there is still data available to be read from this file
	 */
    hasNext?: func -> Bool {
        feof(file) == 0
    }

	/**
	 * Rewind this stream of `offset` bytes.
	 * 
	 * @return true if successful
	 */
    rewind: func(offset: Int) -> Bool {
		file seek(-offset, SEEK_CUR) == 0
    }

	/**
	 * 
	 */
    mark: func -> Long {
        marker = file tell()
        marker
    }

    reset: func(marker: Long) {
        fseek(file, marker, SEEK_SET)
    }

    close: func {
        file close()
    }

}
