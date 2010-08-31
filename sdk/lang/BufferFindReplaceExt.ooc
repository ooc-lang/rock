 import structs/ArrayList

 extend Buffer {

    /** returns a list of positions where buffer has been found, or an empty list if not */
    findAll: func ( what : This) -> ArrayList <SizeT> {
        findAll( what, true)
    }

    /** returns a list of positions where buffer has been found, or an empty list if not  */
    findAll: func ~withCase ( what : This, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        findAll(what data, what size, searchCaseSensitive)
    }

    findAll: func ~pointer ( what : Char*, whatSize: SizeT, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        if (what == null || whatSize == 0) return ArrayList <SizeT> new(0)
        //cprintf("find called on %p:%s with %p:%s\n", size, data, whatSize, what)
        if(whatSize > 1 && (what + whatSize)@ != '\0') Exception new ("something wrong here!") throw()
        if(whatSize > 1 && (what + 1)@ == '\0') Exception new ("something wrong here!") throw()
        result := ArrayList <SizeT> new (size / whatSize)
        offset : SSizeT = (whatSize ) * -1
        while (((offset = find(what, whatSize, offset + whatSize , searchCaseSensitive)) != -1)) result add (offset)
        //for (elem in result) cprintf("%d\n", elem)
        return result
    }

    /** replaces all occurences of *what* with *whit */
    replaceAll: func ~buf (what, whit : This) {
        replaceAll(what, whit, true);
    }

    replaceAll: func ~bufWithCase (what, whit : This, searchCaseSensitive: Bool) {
        //cprintf("replaceAll called on %p:%s with %p:%s\n", size, data, what size, what)
        //if (_literal?()) _makeWritable()
        if (what == null || what size == 0 || whit == null) return
        l := findAll( what, searchCaseSensitive )
        if (l == null || l size() == 0) return
        newlen: SizeT = size + (whit size * l size()) - (what size * l size())
        result := This new~withSize( newlen, false )

        sstart: SizeT = 0 //source (this) start pos
        rstart: SizeT = 0 //result start pos

        for (item in l) {
            sdist := item - sstart // bytes to copy
            memcpy(result data + rstart, data + sstart, sdist)
            sstart += sdist
            rstart += sdist
            memcpy(result data + rstart, whit data, whit size)
            sstart += what size
            rstart += whit size

        }
        // copy remaining last piece of source
        sdist := size - sstart
        memcpy(result data + rstart, data  + sstart, sdist + 1)    // +1 to copy the trailing zero as well
        setBuffer( result )
    }

    /** replace all occurences of *oldie* with *kiddo* in place/ in a clone, if immutable is set */
    replaceAll: func ~char(oldie, kiddo: Char) {
        if (_literal?()) _makeWritable()
        for(i in 0..size) {
            if((data + i)@ == oldie) (data + i)@ = kiddo
        }
    }
}

extend String {
    findAll: func ( what : This) -> ArrayList <SizeT> { _buffer findAll( what _buffer ) }

    findAll: func ~withCase ( what : This, searchCaseSensitive: Bool) -> ArrayList <SizeT> {
        _buffer findAll~withCase( what _buffer, searchCaseSensitive )
    }
}