/** 
 * Set text colors and attributes for VT100 compatible terminals
 * @author eagle2com
 */

Attr: class {
    /* text attribute codes */
    /* Reset All Attributes (return to normal mode) */
    reset =   0,
    /* Bright (Usually turns on BOLD) */        
    bright =  1,    
    /* Dim    */            
    dim =     2,    
    /* Underline */                
    under =   3,        
    /* Blink (Does this really work?????) */        
    blink =   5,    
    /* Reverse (swap background and foreground colors) */                
    reverse = 7,     
    /* Hidden */
    hidden =  8 : static const Int     
}


Color: class {    
    /* Foreground color codes */
    black =      30,
    red =        31,
    green =      32,
    yellow =     33,
    blue  =      34,
    magenta =    35,
    cyan =       36,
    grey =       37,
    white  =     38    : static const Int
}

Terminal: class {
    
    /* Background color codes are the same as Foreground + 10
     * example: background blue = 34 + 10 = 44
     */
    
    /** Set foreground and background color */
    setColor: static func(f,b: Int) {
        setFgColor(f);
        setBgColor(b);
    }
    
    /** Set foreground color */
    setFgColor: static func(c: Int) {
        if(c >= 30 && c <= 37) {
            printf("\033[%dm",c);
        }
    }
    
    /** Set background color */
    setBgColor: static func(c: Int) {
        if(c >= 30 && c <= 37) {
            printf("\033[%dm",c + 10);
        }
    }
    
    /** Set text attribute */
    setAttr: static func(att: Int) {
        if(att >= 0 && att <= 8) {
            printf("\033[%dm",att);
        }
    }
    
    /* Set reset attribute =) */
    /** Reset the terminal colors and attributes */
    reset: static func() {
        setAttr(Attr reset);
    }
}
