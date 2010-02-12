
VersionSpec: abstract class {
    
    toString: abstract func -> String
    
}

VersionName: class extends VersionSpec {
    
    name: String
    
    init: func (=name) {}
    
    toString: func -> String { name }
    
}

VersionNegation: class extends VersionSpec {

    spec: VersionSpec
    
    init: func(=spec) {}
    
    toString: func -> String { '!' + spec toString() }
    
}

VersionAnd: class extends VersionSpec {
    
    specLeft, specRight: VersionSpec
    
    init: func (=specLeft, =specRight) {}
    
    toString: func -> String { specLeft toString() + " && " + specRight toString() }
    
}

VersionOr: class extends VersionSpec {

    specLeft, specRight: VersionSpec
    
    init: func (=specLeft, =specRight) {}
    
    toString: func -> String { specLeft toString() + " || " + specRight toString() }
    
}
