import io/Reader

/**
 * The writer interface provides a medium-independent way to write characters
 * to anything.
 */
Writer: abstract class {
    
    //writef: abstract func(fmt: String, ...) 
    
    //vwritef: abstract func(fmt: String, args: VaList)
    
    close: abstract func()
    
    write: abstract func ~chr (chr: Char)
    
    write: abstract func(chars: String, length: SizeT) -> SizeT
        
    write: func ~implicitLength (chars: String) -> SizeT {
        write(chars, chars length())
    }

    /**
        Copies data from a Reader into this Writer.

        :param bufferSize: size in bytes of the internal transfer buffer
        :return: total bytes transfered
    */
    write: func ~fromReader(source: Reader, bufferSize: SizeT) -> SizeT {
        buffer := String new(bufferSize)
        cursor, bytesRead, bytesTransfered: Int
        cursor = 0; bytesTransfered = 0

        while(source hasNext()) {
            bytesRead = source read(buffer, cursor, bufferSize)
            bytesTransfered += this write(buffer, bytesRead)
        }

        return bytesTransfered
    }
    /**
        Same as write(source, bufferSize) except uses a default buffer size of 8192 bytes.
    */
    write: func ~fromReaderDefaultBufferSize(source: Reader) {
        write(source, 8192)
    }
}
