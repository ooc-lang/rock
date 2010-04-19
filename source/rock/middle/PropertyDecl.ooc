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

    /** create default getter for me. */
    setDefaultGetter: func {
        // a default getter just returns the value.
        decl := FunctionDecl new("__defaultGet__", token)
        access := VariableAccess new(this name, token)
        decl body add(access)
        setGetter(decl)
        decl body toString() println()
    }

    getSetterName: func -> String {
        "__set%s__" format(name)
    }

    getGetterName: func -> String {
        "__get%s__" format(name)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        // get and store the class.
        node := trail peek()
        if(!node instanceOf(ClassDecl)) {
            token throwError("Expected ClassDecl, got %s" format(node toString()))
        }
        cls = node as ClassDecl
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
            trail push(this)
            setter resolve(trail, res)
            trail pop(this)
        }
        super(trail, res)
        return Responses OK
    }

    /** resolve `set` and `get` functions to `getter` and `setter` */
    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        match call name {
            case "get" => {
                call setName(getGetterName())
                cls resolveCall(call, res, trail)
            }
            case "set" => {
                call setName(getSetterName())
                cls resolveCall(call, res, trail)
            }
        }
        0
    }

    /** here for the resolving phase in `init`. Not the nicest way, but works. */
    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) {
        if(access name == this name) {
            cls resolveAccess(access, res, trail)
        }
    }

    /** return true if getters and setters should be used in this context */
    inOuterSpace: func (trail: Trail) -> Bool {
        !trail data contains(setter) && !trail data contains(getter) && !trail data contains(this)
    }
}
