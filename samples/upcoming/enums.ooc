
// summary: comma and newline are valid separators, can assign value with =,
// can specify progression, and extern() aliases. An extern enum does no
// namespacing at all, for covering C types


// pure ooc enum

Color: enum {
    red, green, blue // generates C name Color__red, Color__green, Color__blue
}

c := Color red

// ooc enums with specified values

Number: enum {
    zero, one, two, five = 5, six
}

n := Number five

// ooc enums with specified progression

Numbers: enum(+1) {
    one = 1, two, three
}

Flags:   enum(*2) {
    one = 1, two, four, eight
}

// specified progression + 

// covering a C enum

ShutdownParam: extern enum {
    SHUT_RD    // generate C name SHUT_RD
    SHUT_WR    // generate C name SHUT_WR
    SHUT_RDWR  // generate C name SHUT_RDWR
}

myVal := ShutdownParam SHUT_RD


// aliasing names to something sane

ShutdownParam: extern enum {
    extern(SHUT_RD)   read        // generate C name SHUT_RD
    extern(SHUT_WR)   write       // generate C name SHUT_WR
    extern(SHUT_RDWR) readwrite   // generate C name SHUT_RDWR
}

myVal := ShutdownParam read
