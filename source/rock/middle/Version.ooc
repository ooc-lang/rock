import ControlStatement, Scope, Visitor, Node
import ../frontend/Token
import ../backend/cnaughty/AwesomeWriter // TODO: move AwesomeWriter somewhere else!
import structs/HashMap

import tinker/[Trail, Resolver, Response]

VersionBlock: class extends ControlStatement {
    
    spec: VersionSpec
    
    init: func ~verBlock (=spec, .token) {
        super(token)
    }
    
    accept: func (v: Visitor) {
        v visitVersionBlock(this)
    }
    
    getSpec: func -> VersionSpec { spec }
    
    toString: func -> String { spec toString() }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        if(!super(trail, res) ok()) return Responses LOOP
        
        return spec resolve()
    }
    
    isResolved: func -> Bool { spec isResolved() }
    
}

VersionSpec: abstract class {
    
    token: Token
    
    init: func(=token) {}
    
    toString: abstract func -> String
    
    write: abstract func (w: AwesomeWriter)
    
    resolve: abstract func -> Response
    
    isResolved: abstract func -> Bool
    
}

builtinNames := HashMap<String, String> new()

{
    // ooc's excuse for a map literal (so far ^^)    
    builtinNames put("windows", 	"__WIN32__) || defined(__WIN64__") // FIXME: is that right?
    builtinNames put("linux", 	"__linux__")
    builtinNames put("solaris", 	"__sun")
    builtinNames put("unix", 	"__unix__")
    builtinNames put("beos", 	"__BEOS__")
    builtinNames put("haiku", 	"__HAIKU__")
    builtinNames put("apple", 	"__APPLE__")
    builtinNames put("gnuc", 	"__GNUC__")
    builtinNames put("i386", 	"__i386__")
    builtinNames put("x86", 		"__X86__")
    builtinNames put("x86_64", 	"__x86_64__")
    builtinNames put("ppc", 		"__ppc__")
    builtinNames put("ppc64",	"__ppc64__")
    builtinNames put("64", 		"__x86_64__) || defined(__ppc64__")
    builtinNames put("gc",		"__OOC_USE_GC__")
}

VersionName: class extends VersionSpec {
    
    name: String
    resolved := false
    
    init: func ~name (=name, .token) { super(token) }
    
    toString: func -> String { name }
    
    write: func (w: AwesomeWriter) {
        w app("defined("). app(name). app(")")
    }
    
    isResolved : func -> Bool { resolved }
    
    resolve: func -> Response {
        if(isResolved()) return Responses OK
        
        real := builtinNames get(name)
        if(real == null) {
            token throwWarning("Unknown version id: '" + name + "', compiling anyway (who knows?)")
        } else {
            name = real
        }
        
        resolved = true
        return Responses OK
    }
    
}

VersionNegation: class extends VersionSpec {

    spec: VersionSpec
    
    init: func ~negation (=spec, .token) { super(token) }
    
    toString: func -> String { "!(" + spec toString() + ')' }
    
    write: func (w: AwesomeWriter) {
        w app("!(")
        spec write(w)
        w app(")")
    }
    
    isResolved : func -> Bool { spec isResolved() }
    
    resolve: func -> Response {
        spec resolve()
    }
    
}

VersionAnd: class extends VersionSpec {
    
    specLeft, specRight: VersionSpec
    
    init: func ~and (=specLeft, =specRight, .token) { super(token) }
    
    toString: func -> String { '(' + specLeft toString() + " && " + specRight toString() + ')' }
    
    write: func (w: AwesomeWriter) {
        w app("(")
        specLeft  write(w)
        w app(" && ")
        specRight write(w)
        w app(")")
    }
    
    isResolved : func -> Bool { specLeft isResolved() && specRight isResolved() }
    
    resolve: func -> Response {
        if(!specLeft  resolve() ok()) return Responses LOOP
        if(!specRight resolve() ok()) return Responses LOOP
        return Responses OK
    }
    
}

VersionOr: class extends VersionSpec {

    specLeft, specRight: VersionSpec
    
    init: func ~or (=specLeft, =specRight, .token) { super(token) }
    
    toString: func -> String { '(' + specLeft toString() + " || " + specRight toString() + ')' }
    
    write: func (w: AwesomeWriter) {
        w app("(")
        specLeft  write(w)
        w app(" || ")
        specRight write(w)
        w app(")")
    }
    
    isResolved : func -> Bool { specLeft isResolved() && specRight isResolved() }
    
    resolve: func -> Response {
        if(!specLeft  resolve() ok()) return Responses LOOP
        if(!specRight resolve() ok()) return Responses LOOP
        return Responses OK
    }
    
}
