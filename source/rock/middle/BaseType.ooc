import structs/[List, ArrayList], text/Buffer

import ../backend/cnaughty/AwesomeWriter, ../frontend/BuildParams
import tinker/[Response, Resolver, Trail]

import Type, Declaration, VariableAccess, VariableDecl, TypeDecl,
       InterfaceDecl, Node, ClassDecl, CoverDecl

BaseType: class extends Type {

    ref: Declaration = null
    name: String
    
    typeArgs: List<VariableAccess> = null
    
    init: func ~baseType (=name, .token) { super(token) }
    
    pointerLevel: func -> Int { 0 }
    
    isPointer: func -> Bool { name == "Pointer" }
    
    write: func (w: AwesomeWriter, name: String) {
        if(getRef() == null) {
            Exception new(This, "Trying to write unresolved type " + toString()) throw()
        }
        match {
            case getRef() instanceOf(InterfaceDecl)=> writeInterfaceType(w, getRef() as InterfaceDecl)
            case getRef() instanceOf(TypeDecl)     => writeRegularType  (w, getRef() as TypeDecl)
            case getRef() instanceOf(VariableDecl) => writeGenericType  (w, getRef() as VariableDecl)
        }
        if(name != null) w app(' '). app(name)
    }
    
    writeInterfaceType: func (w: AwesomeWriter, id: InterfaceDecl) {
        w app(id getFatType() getInstanceType())
    }
    
    writeRegularType: func (w: AwesomeWriter, td: TypeDecl) {
        if(td isExtern()) {
            w app(td getExternName())
            return
        }
        
        w app(td underName())
        if(td instanceOf(ClassDecl)) {
            w app("*")
        }
    }
    
    writeGenericType: func (w: AwesomeWriter, vd: VariableDecl) {
        w app("uint8_t*")
    }
    
    equals: func (other: This) -> Bool {
        if(other class != this class) return false
        return (other as BaseType name equals(name))
    }
    
    addTypeArg: func (typeArg: VariableAccess) -> Bool {
        if(!typeArgs) typeArgs = ArrayList<VariableAccess> new()
        typeArgs add(typeArg); true
    }
    
    getName: func -> String { name }
    
    suggest: func (decl: Declaration) -> Bool {
        ref = decl
        if(name == "This" && getRef() instanceOf(TypeDecl)) {
            tDecl := getRef() as TypeDecl
            name = tDecl getName()
        }
        return true
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
    
        if(isResolved()) return Responses OK
        
        if(!getRef()) {
            depth := trail size() - 1
            while(depth >= 0) {
                node := trail get(depth, Node)
                node resolveType(this)
                if(getRef()) break // break on first match
                depth -= 1
            }
        }
        
        if(getRef() == null) {
            if(res fatal) {
                token throwError("Can't resolve type %s!" format(getName()))
            }
            if(res params veryVerbose) {
                printf("     - type %s still not resolved, looping (ref = %p)\n", name, getRef())
            }
            return Responses LOOP
        } else if(getRef() instanceOf(TypeDecl)) {
            tDecl := getRef() as TypeDecl
            if(!tDecl isMeta && !tDecl getTypeArgs() isEmpty()) {
                if(typeArgs == null || typeArgs size() != tDecl getTypeArgs() size()) {
                    token throwError("Missing type parameters for "+toString()+". It should match "+tDecl getInstanceType() toString())
                }
            }
        }
        
        if(typeArgs) {
            trail push(this)
            for(typeArg in typeArgs) {
                response := typeArg resolve(trail, res)
                if(!response ok()) {
                    trail pop(this)
                    return response
                }
            }
            trail pop(this)
        }
        
        return Responses OK
        
    }
    
    isResolved: func -> Bool {
        if(getRef() == null) return false
        if(typeArgs == null) return true
        for(typeArg in typeArgs) if(!typeArg isResolved()) {
            return false
        }
        return true
    }
    
    getRef: func -> Declaration { ref }
    setRef: func (=ref) {}
    
    getTypeArgs: func -> List<VariableAccess> { typeArgs }
    
    getScoreImpl: func (other: Type, scoreSeed: Int) -> Int {
        if(other isGeneric() && other pointerLevel() == 0) {
            // every type is always a match against a flat generic type
            return scoreSeed / 2
        }
        if(isGeneric() && other isPointer()) {
            // a generic value is a match for a pointer
            return scoreSeed / 2
        }
        if(isPointer() && other getRef() instanceOf(ClassDecl)) {
            // objects are references in ooc
            return scoreSeed / 2
        }
        if(getRef() instanceOf(ClassDecl) && other isPointer()) {
            // objects are still references in ooc
            return scoreSeed / 2
        }
        if(isPointer() && other getGroundType() isPointer()) {
            // two pointers = okay
            return scoreSeed / 2
        }
        if(other instanceOf(BaseType)) {
            if(getRef() == null || other getRef() == null) {
                return -1
            }
            
            if(getRef() == other getRef()) {
                // perfect match
                return scoreSeed
            }
            
            if(getName() == other getName()) {
                // *sigh* I wish we didn't have to do that
                return scoreSeed / 2
            }
            
            if(getRef() instanceOf(TypeDecl) && other getRef() instanceOf(TypeDecl)) {
                inheritsScore := getRef() as TypeDecl inheritsScore(other getRef() as TypeDecl, scoreSeed)
                
                // something needs resolving
                if(inheritsScore == -1) {
                    return inheritsScore
                }
                
                // cool, a match =)
                if(inheritsScore > 0) return inheritsScore
            }
            
            if(isNumericType() && other isNumericType()) {
                // Only half a match - it's not too good to mix integer types. Maybe we need more safety here?
                return scoreSeed / 2
            }
        }
        
        return This NOLUCK_SCORE // no luck.
    }
    
    dereference: func -> This {
        digged := dig()
        if(digged) {
            return digged dereference()
        }
        null
    }
    
    clone: func -> This {
        copy := new(name, token)
        if(getTypeArgs()) for(typeArg in getTypeArgs()) {
            copy addTypeArg(typeArg)
        }
        copy setRef(getRef())
        copy
    }
    
    dig: func -> Type {
        if(getRef() != null && getRef() instanceOf(CoverDecl)) {
            return ref as CoverDecl getFromType()
        }
        return null
    }
    
    inheritsFrom: func (t: Type) -> Bool {
        if(!t instanceOf(BaseType)) return false
        bt := t as BaseType
        if(   ref == null || !   ref instanceOf(TypeDecl)) return false
        if(bt ref == null || !bt ref instanceOf(TypeDecl)) return false
        
        return ref as TypeDecl inheritsFrom(bt ref as TypeDecl)
    }
    
    replace: func (oldie, kiddo: Node) -> Bool {
        if(typeArgs) return typeArgs replace(oldie, kiddo)
        false
    }
    
    toString: func -> String {
        if(typeArgs == null) return getName()
        
        sb := Buffer new()
        sb append(getName())
        sb append("<")
        isFirst := true
        if(typeArgs) for(typeArg in typeArgs) {
            if(isFirst) isFirst = false
            else        sb append(", ")
            sb append(typeArg toString())
        }
        sb append(">")
        return sb toString()
    }
    
    searchTypeArg: func (typeArgName: String) -> Type {
        if(getRef() == null) return null
        
        if(!getRef() instanceOf(TypeDecl)) {
            // only TypeDecl have typeArgs anyway.
            return null
        }
        
        typeRef := getRef() as TypeDecl
        if(typeRef typeArgs == null) return null
        
        j := 0
        for(arg in typeRef typeArgs) {
            if(arg getName() == typeArgName) {
                //printf("Looking for %s in %s (ref %s), candidate = %s, j = %d, typeArgs size() = %d\n", typeArgName, toString(), typeRef toString(), arg getName(), j, typeArgs ? typeArgs size() : -1)
                if(typeArgs == null || typeArgs size() <= j) {
                    continue
                }
                candidate := typeArgs get(j)
                ref := candidate getRef()
                if(ref == null) return null
                result : Type = null
                
                //printf("Found candidate %s for typeArg %s\n", candidate toString(), typeArgName)
                if(ref instanceOf(TypeDecl)) {
                    // resolves to a known type
                    result = candidate getRef() as TypeDecl getInstanceType()
                } else {
                    // resolves to an access to another generic type
                    result = BaseType new(ref as VariableDecl getName(), token)
                }
                return result
            }
            j += 1
        }
        
        superType := typeRef getSuperType()
        if(superType != null) {
            //printf("Searching for <%s> in super-type %s\n", typeArgName, superType toString())
            return superType searchTypeArg(typeArgName)
        }
        
        return null
    }

}
