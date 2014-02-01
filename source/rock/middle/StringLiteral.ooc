import structs/ArrayList
import ../frontend/[Token, BuildParams]
import Literal, Visitor, Type, BaseType, VariableDecl, VariableAccess,
        Statement, Module, FunctionDecl, FunctionCall, Expression, TypeDecl
import tinker/[Response, Resolver, Trail, Errors]

StringLiteral: class extends Literal {

    value: String

    raw? := false

    objectType := static BaseType new("String", nullToken)
    rawType := static BaseType new("CString", nullToken)

    init: func ~empty (.token) {
        init("", token)
    }

    init: func ~stringLiteral (=value, .token) {
        super(token)
    }

    clone: func -> This { new(value clone(), token) }

    accept: func (visitor: Visitor) { visitor visitStringLiteral(this) }

    getType: func -> Type { raw? ? rawType : objectType }

    toString: func -> String { "\"" + value + "\"" }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {

        if(!super(trail, res) ok()) return Response LOOP

        if(!raw?) {
            // String object handling
            parent := trail peek()
            if(parent class != VariableDecl) {
                {
                    idx := trail find(FunctionDecl)
                    if(idx == -1) return Response OK
                }
                
                vDecl := VariableDecl new(null, generateTempName("strLit"), this, token)
                vDecl isGenerated = true
                vDecl isStatic = true
                vAcc := VariableAccess new(vDecl, token)
                
                trail module() body add(0, vDecl)
                if(!parent replace(this, vAcc)) {
                    res throwError(CouldntReplace new(token, this, vAcc, trail))
                }
            }
        }

        return Response OK
    }

}

InterpolatedStringLiteral: class extends StringLiteral {
    // We use two ArrayLists, one that holds string pieces and one that holds interpolated expressions
    // If we have an interpolated string with no characters between two interpolations, an empty string should be added to the string array
    // So finally the size of the string array is guaranteed to be greater than one than the expressions (the last element is an empty string)
    // The only issue is a remaining piece of text that is not added because addExpr is not called.
    // This piece of text is added on when resolving and as such we should take it into account in all other methods that could be called before resolving (see toString)

    strings := ArrayList<String> new()
    expressions := ArrayList<Expression> new()

    init: super func ~stringLiteral

    init: func ~fromLit (lit: StringLiteral) {
        init(lit value ? lit value : "", lit token)
    }

    addExpr: func (expr: Expression) {
        // So when we add an expression, we push 'value' to the string array and then empty it in addition to pushing the expression
        // The AST builder keeps on adding text chuncks to value, then it reaches an expression, then the value is pushed and emptied and so on
        strings add(value)
        value = ""

        expressions add(expr)
    }

    toString: func -> String {
        buff := Buffer new()
        buff append('"')

        for(i in 0 .. strings getSize()) {
            str := strings[i]
            buff append(str)

            if(i < expressions getSize()) {
                expr := expressions[i]
                buff append("\#{ %s }" format(expr toString()))
            }
        }

        if(value) buff append(value)
        buff append('"')

        buff toString()
    }

    resolve: func(trail: Trail, res: Resolver) -> Response {
        // Resolve all expressions first
        expressionsDone := true
        trail push(this)
        for (expr in expressions) {
            response := expr resolve(trail, res)
            if (!response ok() || !expr isResolved()) {
                expressionsDone = false
            }
        }
        trail pop(this)
        if (!expressionsDone) {
            res wholeAgain(this, "Need all expressions to be resolved before formatting.")
            return Response OK
        }

        // What we need to do is basically make a simple string literal,
        // replacing interpolated arguments with format specifiers then call
        // format on it If the interpolated arguments are of a base type
        // (numeric or string), they are directly passed to format with the
        // correct type specifier
        //
        // Else, we look for toString() methods up in the dependency tree until
        // we find one (if any) We must add the last piece of text to our
        // string array and we null it so we don't add it multiple times
        // because of many resolve calls
        if(value) {
            strings add(value)
            value = null
        }

        args := ArrayList<Expression> new(expressions getSize())
        literalBuffer := Buffer new()

        trail push(this)
        for(i in 0 .. strings getSize()) {
            // First we push a text chunck
            literalBuffer append(strings[i])

            // Now, if we do have an expression, we must go to serious business
            if(i == expressions getSize()) break
            
            expr := expressions[i]
            type := expr getType()

            if(!type || !type getRef()) {
                trail pop(this)
                res wholeAgain(this, "expr type or type ref is null")
                return Response OK
            }

            specifier := match {
                case type isFloatingPointType() => "%f"
                case type isIntegerType() => "%d"
                case => "%s"
            }

            literalBuffer append(specifier)

            // Now let's start investigating the nature of the interpolated expression
            if(type isNumericType() || \
              (type instanceOf?(BaseType) && (type equals?(objectType) || type equals?(rawType) || \
                type as BaseType inheritsFrom?(objectType) || type as BaseType inheritsFrom?(rawType)))) {

                // We have a basic type that format() can handle, so we add it to the argument list as is
                args add(expr)
                continue
            }

            if(!res fatal) {
                // So we must make sure that we have all super-refs of our type right up to Object to be able to look up a toString method
                // Also, we make sure all the ref's have metas as well
                ref := type getRef()
                objectReached? := false
                while(ref && ref instanceOf?(TypeDecl)) {
                    ref = ref as TypeDecl isMeta ? ref as TypeDecl getNonMeta() : ref

                    if(!ref as TypeDecl getMeta()) {
                        break
                    }

                    if(ref as TypeDecl isObjectClass()) {
                        objectReached? = true
                        break
                    }

                    ref = ref as TypeDecl getSuperType() ? ref as TypeDecl getSuperType() getRef() : null
                }

                if(!objectReached?) {
                    trail pop(this)
                    res wholeAgain(this, "need all of the expression's meta and non meta refs up to Object")
                    return Response OK
                }

                // Let's get back to our first ref, this time knowing it is a TypeDecl
                typeDecl := type getRef() as TypeDecl
                fail := true
                while(typeDecl) {
                    if(!typeDecl isMeta) typeDecl = typeDecl getMeta()

                    // Let's try to find a toString method that matches our needs
                    fDecl := typeDecl lookupFunction("toString", null)

                    if(fDecl) {
                        returnType := fDecl returnType

                        if(fDecl args empty?() && \
                           returnType instanceOf?(BaseType) && \
                           (returnType equals?(objectType) || returnType as BaseType inheritsFrom?(objectType))) {

                            // It matches! o/
                            toStringCall := FunctionCall new(expr, "toString", expr token)
                            args add(toStringCall)
                            fail = false
                            break
                        }
                    }

                    // If we don't check that the typeDecl is not a root class, this results in an infinite loop (Object -> Class -> Object -> ...)
                    // Also, we know that Object and Class do not define a toString() method (if that is too much of an assumption considering custom SDKs, let us know)
                    typeDecl = match (typeDecl getSuperType() != null && !typeDecl getSuperType() getRef() as TypeDecl isRootClass()) {
                        case true => typeDecl getSuperType() getRef()
                        case => null
                    }
                }

                if(fail) {
                    res throwError(InvalidInterpolatedExpressionError new(token, \
                        "Expression %s of type %s cannot be interpolated to string as it is neither a base type nor has a valid toString method." format(expr toString(), type toString())))
                }
            }

        }
        trail pop(this)

        // All that's left is building our format final string literal and the format call and replacing the interpolated string literal with it
        literal := StringLiteral new(literalBuffer toString(), token)
        formatCall := FunctionCall new(literal, "format", token)
        formatCall args = args
        parent := trail peek()
        if(!parent replace(this, formatCall)) {
            res throwError(CouldntReplace new(token, this, formatCall, trail))
        }

        res wholeAgain(this, "Just got replaced o/")
        Response OK
    }

    isResolved: func -> Bool {
        // we always end up being replaced, so we're never resolved
        // as long as we exist in the AST
        false
    }

    replace: func (oldie, kiddo: Statement) -> Bool {
        match oldie {
            case e1: Expression =>
                match kiddo {
                    case e2: Expression =>
                        return expressions replace(e1, e2)
                }
        }
        false
    }

}

InvalidInterpolatedExpressionError: class extends Error {
    init: super func ~tokenMessage
}
