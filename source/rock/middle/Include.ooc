IncludeMode: cover from Int

IncludeModes: class {
    LOCAL = 1,
    PATHY = 2 : static const IncludeMode
}

Include: class {
    
    path: String
    mode: IncludeMode
    
    init: func (=path, =mode) {}
    
}
