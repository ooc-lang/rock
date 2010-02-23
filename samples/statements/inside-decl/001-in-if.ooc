
Node: class {
    
    _parent: Node = null
    name: String
    
    init: func ~parentName (=_parent, =name) {}
    init: func ~name (=name) {}
    
    parent: func -> Node { _parent }
    
    print: func {
        if(parent := parent()) {
            parent print()
        }
        name println()
    }
    
}

main: func {
    Node new(Node new(Node new("Earth"), "Tree"), "Apple") print()
}

