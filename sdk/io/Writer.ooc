import io/Reader

/**
   The writer interface provides a medium-independent way to write
   bytes to anything.

   :author: Amos Wenger (nddrylliog)
 */
Writer: abstract class {

    /**
       Write a single character to this stream
     */
    write: abstract func ~chr (chr: Char)

    /**
       Write a given number of bytes to this stream, and return
       the number that has been effectively written.
     */
    write: abstract func(bytes: Char*, length: SizeT) -> SizeT

    /**
       Write a string to this stream.
     */
    write: func ~implicitLength (str: String) -> SizeT {
        write(str _buffer data, str size)
    }
    
    /**
       Write part of a string to this stream.
     */
    write: func ~strGivenLength (str: String, length: SizeT) -> SizeT {
        write(str _buffer data, length)
    }

    /**
       Equivalent of printf, but used to write to this stream.
     */
    writef: final func(fmt: String, args: ...) {
        write(fmt format(args as VarArgs))
    }
    /**
        Copies data from a Reader into this Writer.

        :param bufferSize: size in bytes of the internal transfer buffer
        :return: total bytes transfered
    */
    write: func ~fromReader(source: Reader, bufferSize: SizeT) -> SizeT {
        buffer := Buffer new(bufferSize)
        cursor, bytesTransfered: Int
        cursor = 0; bytesTransfered = 0

        while(source hasNext?()) {
            buffer setLength( source read(buffer data, cursor, bufferSize) )
            bytesTransfered += this write(buffer data, buffer size)
        }

        return bytesTransfered
    }

    /**
        Same as write(source, bufferSize) except uses a default buffer size of 8192 bytes.
    */
    write: func ~fromReaderDefaultBufferSize(source: Reader) {
        write(source, 8192)
    }

    /**
       Close this writer and free the associated system resources, if any.
     */
    close: abstract func

}
