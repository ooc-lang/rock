import ../frontend/Token
import tinker/[Trail, Resolver, Response, Errors]
import Literal, Visitor, Type, BaseType

IntSignedness: enum {
    UNSIGNED
    SIGNED
}

IntWidth: enum {
    INT
    LONG
    LLONG
}

IntBase: enum {
    BINARY = 2
    OCTAL = 8
    DECIMAL = 10
    HEXADECIMAL = 16
}

IntLiteral: class extends Literal {

    value: String
    type: BaseType

    signedness := IntSignedness SIGNED
    width := IntWidth INT
    base := IntBase DECIMAL

    // oy vey..
    number: Int64 { get {
        value toLLong(base as Int)
    } }

    init: func ~fromNumber (number: Int64, .token) {
        init(number toString(), IntBase DECIMAL, token)
    }

    init: func ~fromString (string: String, =base, .token) {
        super(token)
        string = string replaceAll("_", "")

        while (!string empty?()) {
            specifier := string[string size - 1] toLower()
            match specifier {
                case 'l' =>
                    width = match width {
                        case IntWidth INT =>
                            width = IntWidth LONG
                        case IntWidth LONG =>
                            width = IntWidth LLONG
                    }
                case 'u' =>
                    signedness = IntSignedness UNSIGNED
                case =>
                    break // we're good
            }
            string = string[0..-2] // strip suffix
        }
        value = string
        _inferType()
        _cleanValue()
    }

    _inferType: func {
        typeName := match signedness {
            case IntSignedness UNSIGNED =>
                "U"
            case =>
                ""
        }

        typeName += match width {
            case IntWidth LONG =>
                "Long"
            case IntWidth LLONG =>
                "LLong"
            case =>
                "Int"
        }
        type = BaseType new(typeName, nullToken)
        "Found intliteral #{this}"
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        trail push(this)
        response := type resolve(trail, res)
        trail pop(this)

        if (!response ok()) {
            return response
        }

        return Response OK
    }

    _cleanValue: func {
        // binary literals aren't part of the C standard, let's
        // fold them to hexadecimal
        if (base != IntBase BINARY) {
            return
        }

        level := 0
        currVal := 0
        result := ""

        // value has least significant bytes on the right,
        // str and result have them on the left
        str := value reverse()
        while (!str empty?()) {
            current := str[0]
            str = str[1..-1]

            if (current == '1') {
                currVal += (1 << level)
            }
            level += 1

            if (level > 3) {
                result += currVal toHexString()
                currVal = 0
                level = 0
            }
        }

        // if the length of the 101010 chain is not a multiple of 4,
        // write the rest now
        if (level > 0) {
            result += currVal toHexString()
        }

        base = IntBase HEXADECIMAL
        value = result reverse()
    }

    isResolved: func -> Bool {
        type isResolved()
    }

    clone: func -> This { new(value, base, token) }

    accept: func (visitor: Visitor) { visitor visitIntLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String {
        sb := Buffer new()

        // decimal has no prefix
        match base {
            case IntBase BINARY =>
                sb append("0b")
            case IntBase OCTAL =>
                sb append("0")
            case IntBase HEXADECIMAL =>
                sb append("0x")
        }
        sb append(value)
        match signedness {
            case IntSignedness UNSIGNED =>
                sb append("u")
        }
        match width {
            case IntWidth LONG =>
                sb append("l")
            case IntWidth LLONG =>
                sb append("ll")
        }
        sb toString()
    }

}
