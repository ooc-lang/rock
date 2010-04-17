import structs/[ArrayList]
import Type, Declaration, Expression, Visitor, TypeDecl, VariableAccess,
       Node, ClassDecl, FunctionCall, Argument, BinaryOp, Cast, Module,
       Block, Scope, FunctionDecl, Argument, VariableDecl
import tinker/[Response, Resolver, Trail]
import ../frontend/BuildParams

PropertyDecl: class extends VariableDecl {
    getter: FunctionDecl = null
    setter: FunctionDecl = null
    cls: ClassDecl = null

    init: func ~pDecl (.type, .name, .token) {
        init(type, name, null, token)
    }

    setSetter: func (=setter) {}
    setGetter: func (=getter) {}

    getSetterName: func -> String {
        "__set%s__" format(name)
    }

    getGetterName: func -> String {
        "__get%s__" format(name)
    }

    getValueName: func -> String {
        "__%s__" format(name)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        // get and store the class.
        node := trail peek()
        if(!node instanceOf(ClassDecl)) {
            token throwError("Expected ClassDecl, got %s" format(node toString()))
        }
        cls = node as ClassDecl
        // setup value
        // TODO: only do this if there actually is an access to the value in getter/setter. (non-virtual property)
        vDecl := VariableDecl new(type, getValueName(), token)
        cls addVariable(vDecl)
        // setup getter
        if(getter != null) {
            getter setName(getGetterName()) .setReturnType(type)
            cls addFunction(getter)
            // resolve!
            trail push(this)
            getter resolve(trail, res)
            trail pop(this)
        }
        // setup setter
        if(setter != null) {
            // set name, argument type ...
            setter setName(getSetterName())
            arg := setter args[0]
            // replace `assign` with `conventional`.
            if(arg instanceOf(AssArg)) {
                token throwError("AssArg not yet supported!")
            } else {
                arg setType(this type)
            }
            cls addFunction(setter)
            // let's even resolve it!
            trail push(this)
            setter resolve(trail, res)
            trail pop(this)
        }
        return Responses OK
    }

    /** resolve `set` and `get` functions to `getter` and `setter` */
    resolveCall: func (call: FunctionCall, res: Resolver) -> Int {
        match call name {
            case "get" => {
                call setName(getGetterName())
                cls resolveCall(call, res)
            }
            case "set" => {
                call setName(getSetterName())
                cls resolveCall(call, res)
            }
        }
        0
    }
    
    /** resolve $name accesses to actual value. */
    resolveAccess: func (access: VariableAccess) {
        "--- oh you asking me to resolve %s" format(access toString()) println()
        if(access name == this name) {
            access name = getValueName()
            cls resolveAccess(access)
        }
    }
}
