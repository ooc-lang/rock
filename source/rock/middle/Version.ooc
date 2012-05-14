import ControlStatement, Scope, Visitor, Node
import ../frontend/[BuildParams, Token]
import ../backend/cnaughty/AwesomeWriter // TODO: move AwesomeWriter somewhere else!
import structs/HashMap

import tinker/[Trail, Resolver, Response, Errors]

VersionBlock: class extends ControlStatement {

    spec: VersionSpec

    init: func ~verBlock (=spec, .token) {
        super(token)
    }

    clone: func -> This {
        new(spec, token)
    }

    accept: func (v: Visitor) {
        v visitVersionBlock(this)
    }

    getSpec: func -> VersionSpec { spec }

    toString: func -> String { spec toString() }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        super(trail, res)
    }

    isResolved: func -> Bool { true }

}

VersionSpec: abstract class {

    token: Token

    init: func(=token) {}

    clone: abstract func -> This

    toString: abstract func -> String

    write: abstract func (w: AwesomeWriter)

    equals?: abstract func (other: VersionSpec) -> Bool

    isSatisfied: abstract func (params: BuildParams) -> Bool

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
    builtinNames put("freebsd",		"__FreeBSD__")
    builtinNames put("openbsd",		"__OpenBSD__")
    builtinNames put("netbsd",		"__NetBSD__")
    builtinNames put("dragonfly",	"__DragonFly__")
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

    origin, name: String
    resolved := false

    init: func ~name (=name, .token) {
        super(token)

        origin = name
        real := builtinNames get(name)
        if(real) this name = real
    }

    clone: func -> This {
        new(name, token)
    }

    toString: func -> String { name }

    write: func (w: AwesomeWriter) {
        w app("defined("). app(name). app(")")
    }

    isResolved : func -> Bool { resolved }

    equals?: func (other: VersionSpec) -> Bool {
        if(!other instanceOf?(This)) return false
        other as This name == name
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        if(params isDefined(name)) return true
        if(origin == "64" && params arch == "64") return true

        false
    }

}

VersionNegation: class extends VersionSpec {

    spec: VersionSpec

    init: func ~negation (=spec, .token) { super(token) }

    clone: func -> This {
        new(spec clone(), token)
    }

    toString: func -> String { "!(" + spec toString() + ")" }

    write: func (w: AwesomeWriter) {
        w app("!(")
        spec write(w)
        w app(")")
    }

    equals?: func (other: VersionSpec) -> Bool {
        if(!other instanceOf?(This)) return false
        spec equals?(other as VersionNegation spec)
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        !spec isSatisfied(params)
    }

}

VersionAnd: class extends VersionSpec {

    specLeft, specRight: VersionSpec

    init: func ~and (=specLeft, =specRight, .token) { super(token) }

    clone: func -> This {
        new(specLeft clone(), specRight clone(), token)
    }

    toString: func -> String { "(" + specLeft toString() + " && " + specRight toString() + ")" }

    write: func (w: AwesomeWriter) {
        w app("((")
        specLeft  write(w)
        w app(") && (")
        specRight write(w)
        w app("))")
    }

    equals?: func (other: VersionSpec) -> Bool {
        if(!other instanceOf?(This)) return false
        specLeft equals?(other as VersionAnd specLeft) && specRight equals?(other as VersionAnd specRight)
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        specLeft isSatisfied(params) && specRight isSatisfied(params)
    }

}

VersionOr: class extends VersionSpec {

    specLeft, specRight: VersionSpec

    init: func ~or (=specLeft, =specRight, .token) { super(token) }

    clone: func -> This {
        new(specLeft clone(), specRight clone(), token)
    }

    toString: func -> String { "(" + specLeft toString() + " || " + specRight toString() + ")" }

    write: func (w: AwesomeWriter) {
        w app("((")
        specLeft  write(w)
        w app(") || (")
        specRight write(w)
        w app("))")
    }

    equals?: func (other: VersionSpec) -> Bool {
        if(!other instanceOf?(This)) return false
        specLeft equals?(other as VersionOr specLeft) && specRight equals?(other as VersionOr specRight)
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        specLeft isSatisfied(params) || specRight isSatisfied(params)
    }

}
