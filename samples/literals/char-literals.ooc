
Blah: cover from char {

    // check for white-space characters: space, form-feed ('\f'), newline ('\n'),
    // carriage return ('\r'), horizontal tab ('\t'), and vertical tab ('\v')
    isWhitespace: func -> Bool {
        this == ' '  ||
        this == '\f' ||
        this == '\n' ||
        this == '\r' ||
        this == '\t' ||
        this == '\v'
    }
    
}

main: func {

    printf("'\\n' is whitespace ? %s\n", '\n' as Blah isWhitespace() toString())
    printf(" ' ' is whitespace ? %s\n", ' ' as Blah isWhitespace() toString())
    printf(" 'c' is whitespace ? %s\n", 'c'  as Blah isWhitespace() toString())
    
}
