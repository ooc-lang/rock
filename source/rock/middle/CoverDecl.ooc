import structs/ArrayList
import ../io/TabbedWriter
import ../frontend/Token
import Expression, Type, Visitor, TypeDecl, Node, FunctionDecl,
       FunctionCall
import tinker/[Response, Resolver, Trail]

CoverDecl: class extends TypeDecl {

    fromType: Type
    
    init: func ~coverDeclNoSuper(.name, .token) {
        init(name, null, token)
    }
    
    init: func ~coverDecl(.name, .superType, .token) {
        super(name, superType, token)
    }
    
    accept: func (visitor: Visitor) { visitor visitCoverDecl(this) }
    
    setFromType: func (=fromType) {
        for(addon in getAddons()) {
            addon getNonMeta() as CoverDecl setFromType(fromType)
        }
    }    
    getFromType: func -> Type { fromType }
    
    // all functions of a cover are final, because we don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true
        super(fDecl)
    }
    
    isAddon: func -> Bool { getBase() != null }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
        {
            response := super(trail, res)
            if(!response ok()) return response
        }
        
        trail push(this)
        
        if(fromType) {
            response := fromType resolve(trail, res)
            if(!response ok()) {
                //printf("Giving up on cover type %s\n", fromType toString())
                fromType setRef(BuiltinType new(fromType toString(), nullToken))
            }
        }
        
        trail pop(this)
        
        return Responses OK
    }
    
    writeSize: func (w: TabbedWriter, instance: Bool) {
        w app("sizeof("). app(underName()). app(")")
    }
    
    absorb: func (node: CoverDecl) {
        if(!variables isEmpty()) {
            node token printMessage("...while extending cover " + node toString(), "DETAIL")
            token throwError("Attempting to add variables to another cover!")
        }
        getMeta() base = node getMeta()
        printf("%s from %s is absorbing %s from %s\n", toString(), token module toString(), node toString(), node token module toString())
        setFromType(node getFromType())
        node addAddon(this)
    }
    
    addAddon: func (node: CoverDecl) {
        getMeta() getAddons() add(node getMeta())
        printf("%s from %s got %s from %s as addon\n", getMeta() toString(), token module toString(), node getMeta() toString(), node token module toString())
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }
    
}
