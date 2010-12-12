import structs/HashMap

extend String {

    /**
        Replace all template tokens in *this* with the matching value of *values*.

        Example::

            import text/StringTemplate
            values := HashMap<String, String> new()
            values put("what", "world") .put("suffix", "... yay")
            "Hello {{ what }}! {{   suffix}}" formatTermplate(values) println()
            // -> Hello world! ... yay

    */
    formatTemplate: func (values: HashMap<String, String>) -> String {
        length := this length()
        buffer := Buffer new(length)
        p: Char* = this _buffer data
        identifier: Char* = null
        while(p@) {
            if(!identifier && p@ == '{' && (p + 1)@ == '{') {
                /* start of an identifier */
                identifier = p + 2
                p += 2
            } else if(identifier) {
                if(p@ == '}' && (p + 1)@ == '}') {
                    /* end of an identifier! */
                    /* skip spaces at the end of the identifier */
                    end := p - 1
                    while(end@ == ' ') { end -= 1 }
                    /* calculate the length */
                    length := (end + 1 - identifier) as SizeT
                    key := Buffer new(length)
                    memcpy(key data, identifier, length)
                    /* (the \0 byte is already set.) */
                    value := values get(key toString())
                    if(!value) {
                        value = "" /* TODO: better error handling. */
                    }
                    buffer append(value)
                    identifier = null
                    p += 2
                } else if(p@ == ' ' && identifier == p) {
                    /* skip spaces at the beginning of the identifier */
                    identifier += 1
                    p += 1
                } else {
                    /* part of the identifier, skip */
                    p += 1
                }
            } else {
                buffer append(p@)
                p += 1
            }
        }
        return buffer toString()
    }
}
