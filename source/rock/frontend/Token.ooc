import ../middle/Module

/* Will go into the load method of Token */
nullToken : Token
nullToken = Token new(0, 0, null)

Token: cover {
    
    start, length : SizeT
    module: Module
    
    new: static func~fromData (data: Int*, module: Module) -> This {
        this : This
        this start =  data[0]
        this length = data[1]
        this module = module
        return this
    }
    
    new: static func (.start, .length, .module) -> This {
        this : This
        this start =  start
        this length = length
        this module = module
        return this
    }
    
    new: static func~copy (origin: This) -> This {
        // well that's quite stupid. but covers have value semantics
        // already, so no action is needed to make a "copy" of it.
        return origin
    }
    
    toString: func -> String { "[%d, %d]" format(getStart(), getEnd()) }
    
    /*
    get: func(sReader: SourceReader) -> String {
        return sReader getSlice(start, length)
    }
    */
    
    getLength: func -> SizeT {
        return length
    }
    
    getStart: func -> SizeT {
        return start
    }
    
    getEnd: func -> SizeT {
        return start + length
    }

    equals: func (other: This) -> Bool {
        return memcmp(this&, other&, This size) == 0
    }
    
}
