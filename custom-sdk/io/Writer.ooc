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
}
