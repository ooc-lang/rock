import structs/[ArrayList, HashMap]
import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, BaseType, VariableDecl, VariableAccess,
        Statement, Module, FunctionDecl, FunctionCall, Expression, TypeDecl
import tinker/[Response, Resolver, Trail, Errors]

StringLiteral: class extends Literal {

    value: String
    raw := false
    objectType := static BaseType new("String", nullToken)
    rawType := static BaseType new("CString", nullToken)

    // Map of indices and expressions that hold all interpolated expressions of the string
    interpolatedExpressions := HashMap<Int, Expression> new()

    init: func ~stringLiteral (=value, .token) {
        super(token)
    }

    init: func ~emptyStringLiteral {}

    clone: func -> This {
        clone := new(value clone(), token)
        clone raw = raw
        clone interpolatedExpressions = interpolatedExpressions clone()
        clone
    }

    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { raw ? rawType : objectType }

    isInterpolated: func -> Bool { !interpolatedExpressions empty?() }

    toString: func -> String {
        match getType() {
            case rawType => "c\"" + value + "\""
            case         => match isInterpolated() {
                                case false => "\"" + value + "\""
                                case       =>
                                    returned := value clone()
                                    accumulated := 0
                                    interpolatedExpressions each(|pos, expr|
                                        returned = returned substring(0, accumulated + pos) + "\#{ " \
                                                   + expr toString() + " }" + returned substring(accumulated + pos)
                                        accumulated += 5 + expr toString() size
                                    )
                                    "\"" + returned + "\""
                            }
        }
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(!super(trail, res) ok()) return Response LOOP

        // unwrap object string literals, for optimization
        if (!raw) {
            parent := trail peek()
            if(isInterpolated()) {
                "Resolving interpolated %s (value %s)" format(toString(), value) println()
                // Call [String] format
                // We first must build a simple StringLiteral
                // Then a call of format on it, with our interpolated arguments
                // And finally replace ourselves with it :)
                trail push(this)
                accumulated := 0
                literal := value clone()
                for(pos in interpolatedExpressions getKeys()) {
                    expr := interpolatedExpressions get(pos)

                    response := expr resolve(trail, res)
                    if(!response ok()) {
                        trail pop(this) // For some reason undefined variables make this segfault -_-'
                        return response
                    }

                    type := expr getType()
                    specifier := (type isFloatingPointType() ? "%f" : (type isIntegerType() ? "%d" : "%s"))
                    literal = literal substring(0, pos + accumulated) + specifier + literal substring(pos + accumulated)
                    accumulated += 2
                }
                trail pop(this)
                // We now should have a version of our literal with format specifiers
                litExpr := This new(literal, token)
                args := ArrayList<Expression> new()
                interpolatedExpressions each(|pos, expr|
                    type := expr getType()
                    ref := type getRef()
                    fail := false
                    if(!type isNumericType() && !(type instanceOf?(BaseType) && (type equals?(objectType) || type as BaseType subclassOf?(objectType)))) {
                        // If this is not a number or a String, we look for a toString method
                        if(ref) {
                            if(!ref instanceOf?(TypeDecl)) fail = true
                            if(!ref as TypeDecl isMeta) ref = ref as TypeDecl getMeta()
                            fDecl := ref as TypeDecl lookupFunction("toString", null)
                            if(!fDecl) fail = true
                            else {
                                returnType := fDecl returnType
                                if(!fDecl args empty?() || \
                                   !(returnType instanceOf?(BaseType) && (returnType equals?(objectType) ||
                                   returnType as BaseType subclassOf?(objectType)))) fail = true
                                else {
                                    // We have a toString method
                                    toStringCall := FunctionCall new(expr, "toString", expr token)
                                    args add(toStringCall)
                                }
                            }
                        } else {
                            fail = true
                        }
                    } else {
                        // If the expression is a number or a String, add it as is to the arguments
                        args add(expr)
                    }
                    if(fail) {
                        res throwError(InvalidInterpolatedExpressionError new(token, "Expression %s of type %s cannot be interpolated as it is neither a number type nor has a valid toString method." format(expr toString(), type toString())))
                    }
                )
                formatCall := FunctionCall new(litExpr, "format", token)
                formatCall args = args
                if(!parent replace(this, formatCall)) {
                    res throwError(CouldntReplace new(token, this, formatCall, trail))
                }
                "Resolved! Resulted in: %s" format(formatCall toString()) println()
            } else {
                if(parent class != VariableDecl) {
                    {
                        idx := trail find(FunctionDecl)
                        if(idx == -1) return Response OK
                    }
                    vDecl := VariableDecl new(null, generateTempName("strLit"), this, token)
                    vDecl isStatic = true
                    vAcc := VariableAccess new(vDecl, token)

                    trail module() body add(0, vDecl)
                    if(!parent replace(this, vAcc)) {
                        res throwError(CouldntReplace new(token, this, vAcc, trail))
                    }
                }
            }
        } else if(isInterpolated()) {
            res throwError(InvalidStringLiteral new(token, "String literal cannot be both raw and interpolated."))
        }
        return Response OK

    }

}

InvalidStringLiteral: class extends Error {
    init: super func ~tokenMessage
}

InvalidInterpolatedExpressionError: class extends Error {
    init: super func ~tokenMessage
}

