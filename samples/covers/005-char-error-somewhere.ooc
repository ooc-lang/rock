/**
 * character and pointer types
 */
Dude: cover from char {
    
    // check for an alphanumeric character
    isAlphaNumeric: func -> Bool {
        isAlpha() || isDigit()
    }
 
    // check for an alphabetic character
    isAlpha: func -> Bool {
        isLower() || isUpper()
    }
 
    // check for a lowercase alphabetic character
    isLower: func -> Bool {
        this >= 'a' && this <= 'z'
    }
 
    // check for an uppercase alphabetic character
    isUpper: func -> Bool {
        this >= 'A' && this <= 'Z'
    }
 
    // check for a decimal digit (0 through 9)
    isDigit: func -> Bool {
        this >= '0' && this <= '9'
    }
 
    // check for a hexadecimal digit (0 1 2 3 4 5 6 7 8 9 a b c d e f A B C D E F)
    isHexDigit: func -> Bool {
        isDigit() ||
        (this >= 'A' && this <= 'F') ||
        (this >= 'a' && this <= 'f')
    }
 
    // check for a control character
    isControl: func -> Bool {
        (this >= 0 && this <= 31) || this == 127
    }
 
    // check for any printable character except space
    isGraph: func -> Bool {
        isPrintable() && this != ' '
    }
 
    // check for any printable character including space
    isPrintable: func -> Bool {
        this >= 32 && this <= 126
    }
 
    // check for any printable character which is not a space or an alphanumeric character
    isPunctuation: func -> Bool {
        isPrintable() && !isAlphaNumeric() && this != ' '
    }
 
    // check for white-space characters: space, form-feed ('\f'), newline ('\n'),
    // carriage return ('\r'), horizontal tab ('\t'), and vertical tab ('\v')
    isWhitespace: func -> Bool {
        this == ' ' ||
        this == '\n' ||
        this == '\r' ||
        this == '\t' ||
        this == '\f' ||
        this == '\v'
    }
    
    /*
 
    // check for a blank character; that is, a space or a tab
    isBlank: func -> Bool {
        this == ' ' || this == '\t'
    }
 
    toInt: func -> Int {
        if (isDigit()) {
            return (this - '0')
        }
        return -1
    }
 
    toLower: extern(tolower) func -> This
 
    toUpper: extern(toupper) func -> This
 
    toString: func -> String {
        String new(this)
    }
 
    print: func {
        printf("%c", this)
    }
 
    println: func {
        printf("%c\n", this)
    }
    */
    
}

main: func {}
