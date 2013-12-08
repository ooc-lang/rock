import ../frontend/Token
import tinker/[Trail, Resolver, Response, Errors]
import Literal, Visitor, Type, BaseType

FloatWidth: enum {
    FLOAT
    DOUBLE
    LDOUBLE
}

FloatLiteral: class extends Literal {

    exactValue : String
    value: Float
    width := FloatWidth DOUBLE

    type: BaseType

    init: func ~floatLiteral (string: String, .token) {
        string = string replaceAll("_", "")

        while (!string empty?()) {
            specifier := string[string size - 1] toLower()
            match specifier {
                case 'f' =>
                    width = FloatWidth FLOAT
                case 'l' =>
                    width = FloatWidth LDOUBLE
                case =>
                    break // we're done here
            }
            string = string[0..-2] // strip suffix
        }

        exactValue = string
        value = exactValue toFloat()
        super(token)
        _inferType()
    }

    _inferType: func {
        typeName := \
        match width {
            case FloatWidth FLOAT =>
                "Float"
            case FloatWidth LDOUBLE =>
                "LDouble"
            case =>
                "Double"
        }
        type = BaseType new(typeName, nullToken)
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

    isResolved: func -> Bool {
        type isResolved()
    }

    clone: func -> This { new(exactValue, token) }

    accept: func (visitor: Visitor) { visitor visitFloatLiteral(this) }

    getType: func -> Type { type }

    toString: func -> String {
        match width {
            case FloatWidth FLOAT =>
                exactValue + "f"
            case FloatWidth LDOUBLE =>
                exactValue + "l"
            case =>
                exactValue
        }
    }

}
