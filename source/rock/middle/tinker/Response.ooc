
/**
 * Possible Response in the resolve() method.
 */
Response: enum {
    /** All good, keep going */
    OK

    /** Hold up, trail is messed up, need to start again */
    LOOP

    ok:      func -> Bool { this == Response OK }
    loop:    func -> Bool { this == Response LOOP }

    /**
     * @return A textual representation of this response state
     */
    toString: func -> String {
        return match this {
            case This OK   => "OK"
            case This LOOP => "LOOP"
        }
    }
}
