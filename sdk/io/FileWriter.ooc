import io/Writer, io/File
import os/Pipe, os/native/PipeUnix

/**
 * Implement the Writer interface for file output
 * 
 * By default, files are opened in binary mode. If you want to open
 * them in text mode, use the new~withMode variant, but beware: on 
 * mingw, rewind()/mark() won't work correctly.
 * 
 * @author Amos Wenger (nddrylliog)
 */
FileWriter: class extends Writer {

    /** The underlying file descriptor */
    file: FStream

    /**
       Create a new file writer on the given file object.
       @param append If true, appends to the file. If false, overwrites it.
     */
    init: func ~withFile (fileObject: File, append: Bool) {
        init(fileObject getPath(), append)
    }

    /**
       Create a new file write on the given file object, overwriting it.
    */
    init: func ~withFileOverwrite (fileObject: File) {
        init(fileObject, false)
    }

    init: func ~withFileAndFlags (fileObject: File, flags: Int) {
        init(fileObject getPath(), "wb", flags)
    }

    /**
       Create a new file writer on the given file path.
       @param append If true, appends to the file. If false, overwrites it.
     */
    init: func ~withName (fileName: String, append: Bool) {
        // mingw fseek/ftell are *really* unreliable with text mode
        // if for some weird reason you need to open in text mode, use
        // FileWriter new(fileName, "ab") or "wb"
        init(fileName, append ? "ab" : "wb")
    }
            
    init: func ~withMode (fileName, mode: String) {
        file = FStream open(fileName, mode)
        if (!file) {
            // TODO: that's wrong - many other things could happen. Use strerror instead.
            Exception new(This, "File not found: " + fileName) throw()
        }
    }

    init: func ~withModeAndFlags (fileName, mode: String, flags: Int) {
        file = FStream open(fileName, mode, flags)
        if (!file) {
            Exception new(This, "File not found: " + fileName) throw()
        }
    }

    /**
        Create a new file writer from a given FStream
    */
    init: func ~withFStream (=file)

    /**
       Create a new file writer on the given file path, overwriting it.
     */
    init: func ~withNameOverwrite (fileName: String) {
        init(fileName, false)
    }

    createTempFile: static func (pattern: String, mode: String) -> This {
	version (!windows) {
	    return new(fdopen(mkstemp(pattern), mode))
	}
	version (windows) {
	    // mkstemp is missing on Windows, that sucks, but let's use the
	    // worse method instead
	    new(mktemp(pattern) toString(), mode)
	}
	Exception new("FileWriter createTempFile() is unsupported on your os") throw()
	null
    }

    /**
       Write a given number of bytes to this file, and return
       the number that has been effectively written.
     */
    write: func (bytes: Char*, length: SizeT) -> SizeT {
        file write(bytes, 0, length)
    }

    /**
       Write a single byte to this file.
     */
    write: func ~chr (chr: Char) {
        file write(chr)
    }


    /**
       Close this writer and free the associated system resources, if any.
     */
    close: func {
        file close()
    }

    asPipe: func -> Pipe {
        version(unix || apple) {
            return PipeUnix new(-1, file no())
        } else {
            Exception new("FileWriter asPipe() is not supported on your platform") throw()
        }
        null
    }
}
