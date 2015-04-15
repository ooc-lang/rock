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
        spec resolve(trail, res)
        super(trail, res)
    }

}

VersionSpec: abstract class {

    token: Token
    spec: BuiltinSpec
    toplevel := true
    resolved := false

    init: func(=token) {}

    clone: abstract func -> This

    toString: abstract func -> String

    write: abstract func (w: AwesomeWriter)

    equals?: abstract func (other: VersionSpec) -> Bool

    isSatisfied: abstract func (params: BuildParams) -> Bool

    resolve: abstract func (trail: Trail, res: Resolver) -> Response
    
    isResolved: func -> Bool { resolved }

}

/* Built-in spec */

_unknownVersionSpecs := HashMap<String, String> new()
_builtinVersionSpecs := HashMap<String, BuiltinSpec> new()
BuiltinSpec: class {

    condition: String
    prelude: String
    afterword: String

    init: func (=condition)

}

_addBuiltinSpec: func (key, condition: String) {
    realCondition := "defined(%s)" format(condition)
    _builtinVersionSpecs put(key, BuiltinSpec new(realCondition))
}

_addComplexBuiltinSpec: func (key, condition, prelude, afterword: String) {
    spec := BuiltinSpec new(condition)
    spec prelude = prelude
    spec afterword = afterword
    _builtinVersionSpecs put(key, spec)
}

{
    // Microsoft
    _addBuiltinSpec("windows",      "__WIN32__) || defined(__WIN64__")
    _addBuiltinSpec("msvc",         "_MSC_VER")

    // Linux
    _addBuiltinSpec("linux",        "__linux__")
    _addBuiltinSpec("cygwin",       "__CYGWIN__")
    _addBuiltinSpec("mingw",        "__MINGW32__")
    _addBuiltinSpec("mingw64",      "__MINGW64__")

    // Apple
    appleString := "__APPLE__) || defined(__MACH__"
    _addBuiltinSpec("apple", appleString)

    applePrelude := "
#if defined(__APPLE__) && defined(__MACH__)
#ifndef _HAS_TARGET_CONDITIONALS_
#define _HAS_TARGET_CONDITIONALS_
#include <TargetConditionals.h>
#endif
"
    _addComplexBuiltinSpec("ios_simulator", "TARGET_IPHONE_SIMULATOR == 1",
        applePrelude, "#endif")
    _addComplexBuiltinSpec("ios", "TARGET_OS_IPHONE == 1",
        applePrelude, "#endif")
    _addComplexBuiltinSpec("osx", "TARGET_OS_MAC == 1",
        applePrelude, "#endif")

    // BSDs
    _addBuiltinSpec("freebsd",      "__FreeBSD__")
    _addBuiltinSpec("openbsd",      "__OpenBSD__")
    _addBuiltinSpec("netbsd",       "__NetBSD__")
    _addBuiltinSpec("dragonfly",    "__DragonFly__")

    // Other Unices
    _addBuiltinSpec("solaris",      "__sun) && defined(__SVR4")
    _addBuiltinSpec("unix",         "__unix__) && !defined(__MSYS__")

    // BeOSes
    _addBuiltinSpec("beos",         "__BEOS__")
    _addBuiltinSpec("haiku",        "__HAIKU__")

    // archs
    _addBuiltinSpec("arm",          "__arm__")
    _addBuiltinSpec("i386",         "__i386__")
    _addBuiltinSpec("x86",          "__X86__")
    _addBuiltinSpec("x86_64",       "__x86_64__")
    _addBuiltinSpec("ppc",          "__ppc__")
    _addBuiltinSpec("ppc64",        "__ppc64__")
    _addBuiltinSpec("64",           "__x86_64__) || defined(__ppc64__")

    // Various
    _addBuiltinSpec("gnuc",         "__GNUC__")
    _addBuiltinSpec("gc",           "__OOC_USE_GC__")
    _addBuiltinSpec("debug",        "__OOC_DEBUG__")
    _addBuiltinSpec("android",      "__ANDROID__")
}

MixedComplexVersion: class extends Error {

    init: func (.token, condition: String) {
        super(token, "%s is a complex version spec, it has to be alone in the version expression" format(condition))
    }

}

VersionName: class extends VersionSpec {

    name: String

    init: func ~name (=name, .token) {
        super(token)
    }

    clone: func -> This {
        c := new(name, token)
        c spec = spec
        c
    }

    toString: func -> String { name }

    write: func (w: AwesomeWriter) {
        if (spec) {
            w app(spec condition)
        } else {
            w app("defined("). app(name). app(")")
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        spec = _builtinVersionSpecs get(name)
        if (spec) {
            if (spec prelude && !toplevel) {
                res throwError(MixedComplexVersion new(token, name))
            }
        } else {
            if (!_unknownVersionSpecs contains?(name)) {
                _unknownVersionSpecs put(name, name)
                res throwError(Warning new(token, "Unrecognized version: %s" format(name)))
            }
        }
        resolved = true

        Response OK
    }

    equals?: func (other: VersionSpec) -> Bool {
        if(!other instanceOf?(This)) return false
        other as This name == name
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        if(params isDefined(name)) return true
        if(name == "64" && params arch == "64") return true

        false
    }

}

VersionNegation: class extends VersionSpec {

    inner: VersionSpec

    init: func ~negation (=inner, .token) { super(token) }

    clone: func -> This {
        new(inner clone(), token)
    }

    toString: func -> String { "!(" + inner toString() + ")" }

    write: func (w: AwesomeWriter) {
        w app("!(")
        inner write(w)
        w app(")")
    }

    equals?: func (other: VersionSpec) -> Bool {
        match other {
            case n: This =>
                inner equals?(n inner)
            case => false
        }
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        !inner isSatisfied(params)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        inner resolve(trail, res)
        resolved = inner isResolved()
        Response OK
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
        match other {
            case a: This =>
                specLeft equals?(a specLeft) && 
                specRight equals?(a specRight)
            case => false
        }
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        specLeft isSatisfied(params) && specRight isSatisfied(params)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        specLeft resolve(trail, res)
        specRight resolve(trail, res)
        resolved = specLeft isResolved() && specRight isResolved()
        Response OK
    }

}

VersionOr: class extends VersionSpec {

    specLeft, specRight: VersionSpec

    init: func ~or (=specLeft, =specRight, .token) {
        super(token)
        specLeft toplevel = false
        specRight toplevel = false
    }

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
        match other {
            case o: This =>
                specLeft equals?(o specLeft) ||
                specRight equals?(o specRight)
            case => false
        }
    }

    isSatisfied: func (params: BuildParams) -> Bool {
        specLeft isSatisfied(params) || specRight isSatisfied(params)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        specLeft resolve(trail, res)
        specRight resolve(trail, res)
        resolved = specLeft isResolved() && specRight isResolved()
        Response OK
    }

}

