import ControlStatement, Scope, Visitor, Node
import ../backend/cnaughty/AwesomeWriter // TODO: move AwesomeWriter somewhere else!

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
    
}

VersionSpec: abstract class {
    
    toString: abstract func -> String
    
    write: abstract func (w: AwesomeWriter)
    
}

VersionName: class extends VersionSpec {
    
    name: String
    
    init: func (=name) {}
    
    toString: func -> String { name }
    
    write: func (w: AwesomeWriter) {
        w app("defined("). app(name). app(")")
    }
    
}

VersionNegation: class extends VersionSpec {

    spec: VersionSpec
    
    init: func(=spec) {}
    
    toString: func -> String { "!(" + spec toString() + ')' }
    
    write: func (w: AwesomeWriter) {
        w app("!(")
        spec write(w)
        w app(")")
    }
    
}

VersionAnd: class extends VersionSpec {
    
    specLeft, specRight: VersionSpec
    
    init: func (=specLeft, =specRight) {}
    
    toString: func -> String { '(' + specLeft toString() + " && " + specRight toString() + ')' }
    
    write: func (w: AwesomeWriter) {
        w app("(")
        specLeft  write(w)
        w app(" && ")
        specRight write(w)
        w app(")")
    }
    
}

VersionOr: class extends VersionSpec {

    specLeft, specRight: VersionSpec
    
    init: func (=specLeft, =specRight) {}
    
    toString: func -> String { '(' + specLeft toString() + " || " + specRight toString() + ')' }
    
    write: func (w: AwesomeWriter) {
        w app("(")
        specLeft  write(w)
        w app(" || ")
        specRight write(w)
        w app(")")
    }
    
}
