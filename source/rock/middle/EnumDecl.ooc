import structs/[ArrayList, HashMap]
import ../io/TabbedWriter
import TypeDecl, Declaration, Visitor, Node, VariableAccess, Type,
       VariableDecl, IntLiteral, FloatLiteral, Expression, FunctionDecl,
       CoverDecl, Module, StructLiteral, BaseType
import tinker/[Trail, Resolver, Response, Errors]
import ../frontend/Token

EnumDecl: class extends TypeDecl {
    lastElementValue := IntLiteral new(0, nullToken)
    incrementOper := '+'
    incrementStep : Int64 = 1
    fromType: Type

    valuesCoverDecl: CoverDecl
    valuesGlobal: VariableDecl

    init: func ~enumDecl(.name, .token) {
        super(name, token)
        fromType = instanceType
    }

    setFromType: func (=fromType) {}

    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super(trail, res)
            if(!response ok()) return response
        }

        {
            response := fromType resolve(trail, res)
            if(!response ok()) return response
        }

        if (valuesCoverDecl == null) {
            createCovers()
            res wholeAgain(this, "need to resolve coverdecls for enum")
        }

        Response OK
    }

    createCovers: func {
        valuesCoverDecl = CoverDecl new(name + "__values_t", token)
        for (v in getMeta() variables) {
            vDecl := VariableDecl new(BaseType new("Int", token), v name, v token)
            valuesCoverDecl addVariable(vDecl)
        }
        valuesCoverDecl module = token module
        token module addType(valuesCoverDecl)

        elements := ArrayList<Expression> new()
        for (v in getMeta() variables) {
            elements add(VariableAccess new(v, token))
        }

        slit := StructLiteral new(valuesCoverDecl getInstanceType(), elements, token)
        valuesGlobal = VariableDecl new(null, name + "__values", slit, token)
        valuesGlobal isGlobal = true
        token module body add(valuesGlobal)
    }

    addFunction: func (fDecl: FunctionDecl) {
        fDecl setFinal(true)
        super(fDecl)
    }

    addElement: func (element: EnumElement) {
        if(isExtern()) {
            if(!element isExtern()) {
                // Provide a default extern name if none is provided
                element setExternName(element getName())
            }
        } else {
            // If no value is provided for a non-extern element,
            // calculate it by incrementing the last used value.
            if(element valueSet) {
                lastElementValue = element getValue()
            } else {
                updateLastElementValue()
                element setValue(lastElementValue)
            }
        }

        element setType(fromType)
        getMeta() addVariable(element)
    }

    updateLastElementValue: func {
        lastElementValue = match lastElementValue {
                case intLit: IntLiteral =>
                    IntLiteral new(match incrementOper {
                        case '+' =>
                            intLit number + incrementStep
                        case '*' =>
                            intLit number * incrementStep
                    }, intLit token)
                case floatLit: FloatLiteral =>
                    FloatLiteral new(match incrementOper {
                        case '+' =>
                            (floatLit value + incrementStep as Float) toString()
                        case '*' =>
                            (floatLit value * incrementStep as Float) toString()
                    }, floatLit token)
                case =>
                    token module params errorHandler onError(ImpossibleIncrement new(token,
                        "It's impossible to increment implicitly elements of type %s!" format(fromType toString())))
                    return
                    null
        }
    }

    setIncrement: func (=incrementOper, =incrementStep) {}

    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof(")
        if(isExtern()) {
            if(externName && externName != "") {
                w app(externName)
            } else {
                w app(name)
            }
        } else {
            w app("int")
        }
        w app(")")
    }

    accept: func (visitor: Visitor) {
        visitor visitEnumDecl(this)
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }
}

EnumElement: class extends VariableDecl {
    value: Expression
    valueSet := false

    init: func ~enumElementDecl(.type, .name, .token) {
        super(type, name, token)
    }

    setValue: func (=value) { valueSet = true }
    getValue: func -> Expression { value }

    setType: func (=type) {}
    getType: func -> Type { type }

    accept: func (visitor: Visitor) {}

    replace: func (oldie, kiddo: Node) -> Bool { false }
}

ImpossibleIncrement: class extends Error {
    init: super func ~tokenMessage
}

