
/**
 * Possible Response in the resolve() method.
 *
 * @author Amos Wenger (nddrylliog)
 */
Response: enum {
    OK
    LOOP
}

// tihi
extend Response {
    ok:      func -> Bool { this == Response OK }
    loop:    func -> Bool { this == Response LOOP }

    toString: func -> String {
        return match this {
            case This OK   => "OK"
            case This LOOP => "LOOP"
        }
    }
}