import io/[Writer, BufferWriter]
import structs/[Bag, HashBag]
import text/[EscapeSequence]

import Parser

GeneratorError: class extends Exception {
    init: super func ~noOrigin
}

EXCLUDE := const "'" // don't escape the '

generate: func <T> (writer: Writer, obj: T) {
    match T {
        case String => {
            writer write("\"%s\"" format(EscapeSequence escape(obj as String, EXCLUDE) toCString()))
        }
        case Int => {
            writer write(obj as Int toString())
        }
        case Int64 => {
            writer write(obj as Int64 toString())
        }
        case UInt => {
            writer write(obj as UInt toString())
        }
        case SSizeT => { // for int literals
            writer write(obj as SSizeT toString())
        }
        case Bool => {
            writer write((obj as Bool ? "true" : "false"))
        }
        case Pointer => {
            writer write("null")
        }
        case Number => {
            writer write(obj as Number value)
        }
        case HashBag => {
            writer write('{')
            bag := obj as HashBag
            first := true
            for(key: String in bag getKeys()) {
                if(first)
                    first = false
                else
                    writer write(',')
                generate(writer, key)
                writer write(':')
                U := bag getClass(key)
                generate(writer, bag get(key, U))
            }
            writer write('}')
        }
        case Bag => {
            writer write('[')
            bag := obj as Bag
            first := true
            for(i: SizeT in 0..bag getSize()) {
                if(first)
                    first = false
                else
                    writer write(',')
                U := bag getClass(i)
                generate(writer, bag get(i, U))
            }
            writer write(']')
        }
        case => {
            GeneratorError new("Unknown type: %s" format(T name toCString())) throw()
        }
    }
}

generateString: func <T> (obj: T) -> String {
    writer := BufferWriter new()
    generate(writer, obj)
    writer buffer toString()
}
