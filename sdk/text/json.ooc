/*
    A wrapper module for text/json/[Parser,Generator] that doesn't
    pollute the global namespace when imported normally.
    This module provides a `JSON` class with static methods.
*/
import io/[Reader,Writer]
import json/[Generator,Parser] into _JSON

JSON: class {
    parse: static func <T> (reader: Reader, T: Class) -> T {
        _JSON parse(reader, T)
    }

    parse: static func ~string <T> (s: String, T: Class) -> T {
        _JSON parse(s, T)
    }

    generate: static func <T> (w: Writer, obj: T) {
        _JSON generate(w, obj)
    }

    generateString: static func <T> (obj: T) {
        _JSON generateString(obj)
    }
}
