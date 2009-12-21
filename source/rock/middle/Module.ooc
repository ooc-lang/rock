import io/File
import structs/[HashMap, ArrayList]
import ../frontend/[Token, SourceReader]
import Node, FunctionDecl, Visitor, Import, Include, Use, TypeDecl,
       FunctionCall, Type, Declaration, VariableAccess
import tinker/[Response, Resolver, Trail]

Module: class extends Node {

    fullName, simpleName, packageName, underName, pathElement : String
    
    types     := HashMap<TypeDecl> new()
    functions := HashMap<FunctionDecl> new()
    
    includes := ArrayList<Include> new()
    imports  := ArrayList<Import> new()
    uses     := ArrayList<Use> new()
    
    lastModified : Long

    init: func ~module (.fullName, =pathElement, .token) {
        super(token)
        this fullName = fullName replace(File separator, '/')
        idx := fullName lastIndexOf('/')
        
        match idx {
            case -1 =>
                simpleName = fullName clone()
                packageName = ""
            case =>
                simpleName = fullName substring(idx + 1)
                packageName = fullName substring(0, idx)
        }
        
        // FIXME this is incomplete, the correct code is actually
        underName = sanitize(fullName clone())
        
        packageName = sanitize(packageName)
    }
    
    sanitize: func(str: String) -> String {
        return str replace('/', '_') replace('-', '_')
    }
    
    addFunction: func (fDecl: FunctionDecl) {
        functions add(fDecl name, fDecl)
    }
    
    addType: func (tDecl: TypeDecl) {
        types add(tDecl name, tDecl)
    }
    
    accept: func (visitor: Visitor) { visitor visitModule(this) }
    
    getOutPath: func (suffix: String) -> String {
        last := (File new(pathElement) name())
        return (last + File separator) + fullName + suffix
    }
    
    getParentPath: func -> String {
        // FIXME that's sub-optimal
        fileName := pathElement + File separator + fullName + ".ooc"
        parentPath := File new(fileName) parent() path
        return parentPath
    }
    
    resolveAccess: func (access: VariableAccess) {
        
        ref : Declaration = null
        
        ref = types get(access name)
        if(ref != null && access suggest(ref)) {
            return
        }
        
        for(imp in imports) {
            //printf("Looking in import %s\n", imp path)
            ref = imp getModule() types get(access name)
            if(ref != null && access suggest(ref)) {
                //("Found type " + name + " in " + imp getModule() fullName)
                break
            }
        }
        
    }
    
    resolveCall: func (call: FunctionCall) {
        if(call expr != null) return // hmm no member calls for us
        
        //printf("Looking for function %s in module %s!\n", call name, fullName)
        fDecl : FunctionDecl = null
        fDecl = functions get(call name)
        if(fDecl) {
            //"&&&&&&&& Found fDecl for call %s\n" format(call name) println()
            if(call suggest(fDecl)) return
        }
        
        for(imp in imports) {
            fDecl = imp getModule() functions get(call name)
            if(fDecl) {
                //"&&&&&&&& Found fDecl for call %s in module %s\n" format(call name, imp getModule() fullName) println()
                if(call suggest(fDecl)) return
            }
        }
    }
    
    resolveType: func (type: BaseType) {
        
        ref : Declaration = null
        
        ref = types get(type name)
        if(ref != null && type suggest(ref)) {
            return
        }
            
        for(imp in imports) {
            //printf("Looking in import %s\n", imp path)
            ref = imp getModule() types get(type name)
            if(ref != null && type suggest(ref)) {
                //("Found type " + name + " in " + imp getModule() fullName)
                break
            }
        }
        
    }
    
    resolve: func (trail: Trail, res: Resolver) -> Response {
    
        finalResponse := Responses OK
        
        trail push(this)
        
        for(tDecl in types) {
            if(tDecl isResolved()) continue
            response := tDecl resolve(trail, res)
            //printf("response of tDecl %s = %s\n", tDecl toString(), response toString())
            if(!response ok()) {
                finalResponse = response
            }
        }
        
        for(fDecl in functions) {
            if(fDecl isResolved()) continue
            response := fDecl resolve(trail, res)
            //printf("response of fDecl %s = %s\n", fDecl toString(), response toString())
            if(!response ok()) {
                finalResponse = response
            }
        }
        
        trail pop(this)
        
        return finalResponse
    }
    
    toString: func -> String {
        class name + ' ' + fullName
    }
    
    replace: func (oldie, kiddo: Node) -> Bool { false }

}
