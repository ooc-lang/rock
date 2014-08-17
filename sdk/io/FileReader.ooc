import io/[Reader, File]

/**
 * Implement the Reader interface for file input
 * 
 * By default, files are opened in binary mode. If you want to open
 * them in text mode, use the new~withMode variant, but beware: on 
 * mingw, rewind()/mark() won't work correctly.
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
    init: func ~withMode (=fileName, mode: String) {
        file = FStream open(fileName, mode)
        if (!file) {
            err := getOSError()
            Exception new(This, "Couldn't open #{fileName} for reading: #{err}") throw()
        }
    }

    /**
     * Init a file reader from an FStream
     */
    init: func ~fromFStream (=file) {}

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
    read: func (buffer: Char*, offset: Int, count: SizeT) -> SizeT {
        file read(buffer + offset, count)
    }

    read: func ~fullBuffer (buffer: Buffer) {
        count := file read(buffer data, buffer capacity)
        buffer size = count
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

    seek: func (offset: Long, mode: SeekMode) -> Bool {
        file seek(offset, match mode {
            case SeekMode SET => SEEK_SET
            case SeekMode CUR => SEEK_CUR
            case SeekMode END => SEEK_END
            case =>
                Exception new("Invalid seek mode: %d" format(mode)) throw()
                SEEK_SET
        }) == 0
    }

    mark: func -> Long {
        marker = file tell()
        marker
    }

    close: func {
        file close()
    }

}
