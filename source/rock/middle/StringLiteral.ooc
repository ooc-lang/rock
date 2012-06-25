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

    init: func ~emptyStringLiteral { value = "" }

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
                // Call [String] format
                // We first must build a simple StringLiteral
                // Then a call of format on it, with our interpolated arguments
                // And finally replace ourselves with it :)
                trail push(this)
                accumulated := 0
                literalText := value clone()
                for(pos in interpolatedExpressions getKeys()) {
                    expr := interpolatedExpressions get(pos)

                    response := expr resolve(trail, res)
                    if(!response ok()) {
                        trail pop(this)
                        return response
                    }

                    type := expr getType()
                    if(!type || !type getRef()) {
                        trail pop(this)
                        res wholeAgain(this, "expr type or type ref is null")
                        return Response OK
                    } else {
                        // We need the type and its ref to be REALLY resolved, as we access stuff like subclassOf?
                        response := type resolve(trail, res)
                        if(!response ok()) {
                            trail pop(this)
                            return response
                        }
                        response = type getRef() resolve(trail, res)
                        if(!response ok()) {
                            trail pop(this)
                            return response
                        }
                    }
                    specifier := (type isFloatingPointType() ? "%f" : (type isIntegerType() ? "%d" : "%s"))
                    literalText = literalText substring(0, pos + accumulated) + specifier + literalText substring(pos + accumulated)
                    accumulated += 2
                }
                trail pop(this)
                // We now should have a version of our literal with format specifiers
                literal := This new(literalText, token)
                args := ArrayList<Expression> new()
                interpolatedExpressions each(|pos, expr|
                    type := expr getType()
                    ref := type getRef()
                    fail := true
                    if(!type isNumericType() && !(type instanceOf?(BaseType) && (type equals?(objectType) || type as BaseType subclassOf?(objectType)))) {
                        // If this is not a number or a String, we look for a toString method
                        while(ref) {
                            if(!ref instanceOf?(TypeDecl)) {
                                ref = null
                                break
                            } else {
                                if(!ref as TypeDecl isMeta) ref = ref as TypeDecl getMeta()
                                fDecl := ref as TypeDecl lookupFunction("toString", null)
                                if(fDecl) {
                                    returnType := fDecl returnType
                                    if(fDecl args empty?() && \
                                       returnType instanceOf?(BaseType) && \
                                       (returnType equals?(objectType) ||
                                        returnType as BaseType subclassOf?(objectType))) {
                                        // We have a toString method, so our argument is a call to it
                                        toStringCall := FunctionCall new(expr, "toString", expr token)
                                        args add(toStringCall)
                                        fail = false
                                        break
                                    }
                               }
                            }
                            ref = ref as TypeDecl getSuperType() getRef()
                        }
                    } else {
                        // If the expression is a number or a String, add it as is to the arguments
                        args add(expr)
                        fail = false
                    }
                    if(fail) {
                        res throwError(InvalidInterpolatedExpressionError new(token, "Expression %s of type %s cannot be interpolated in this string as it is neither a number nor a String type and it has no valid toString method." format(expr toString(), type toString())))
                    }
                )
                formatCall := FunctionCall new(literal, "format", token)
                formatCall args = args
                if(!parent replace(this, formatCall)) {
                    res throwError(CouldntReplace new(token, this, formatCall, trail))
                }
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
            res throwError(InvalidStringLiteral new(token, "String literal cannot be both raw and interpolated with values."))
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

