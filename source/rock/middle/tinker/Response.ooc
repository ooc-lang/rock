include stdint

Response: cover from uint8_t {
    
    ok:      func -> Bool { this == Responses OK }
    loop:    func -> Bool { this == Responses LOOP }
    restart: func -> Bool { this == Responses RESTART }
    
    toString: func -> String {
        return match this {
            case 0 => "OK"
            case 1 => "LOOP"
            case 2 => "RESTART"
        }
    }
    
}

Responses: class {
 
    OK = 0,
    LOOP = 1,
    RESTART = 2 : static Response
    
}
