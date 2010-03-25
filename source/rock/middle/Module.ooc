import io/File, text/EscapeSequence
import structs/[HashMap, ArrayList, List, OrderedMultiMap]
import ../frontend/[Token, SourceReader, BuildParams]
import Node, FunctionDecl, Visitor, Import, Include, Use, TypeDecl,
       FunctionCall, Type, Declaration, VariableAccess, OperatorDecl,
       Scope, NamespaceDecl
import tinker/[Response, Resolver, Trail]

Module: class extends Node {

    path, fullName, simpleName, packageName, underName, pathElement : String

    types      := OrderedMultiMap<String, TypeDecl> new()
    functions  := OrderedMultiMap<String, FunctionDecl> new()
    operators  := ArrayList<OperatorDecl> new()

    includes   := ArrayList<Include> new()
    imports    := ArrayList<Import> new()
    namespaces := HashMap<String, NamespaceDecl> new()
    uses       := ArrayList<Use> new()

    funcTypesMap := HashMap<String, FuncType> new()

    body       := Scope new()

    lastModified : Long

    init: func ~module (.fullName, =pathElement, .token) {
        super(token)
        this path = fullName clone()
        this fullName = fullName replace(File separator, '/')
        idx := this fullName lastIndexOf('/')

        match idx {
            case -1 =>
                simpleName = this fullName clone()
                packageName = ""
            case =>
                simpleName = this fullName substring(idx + 1)
                packageName = this fullName substring(0, idx)
        }

        underName = sanitize(this fullName clone())
        packageName = sanitize(packageName)
    }

    getLoadFuncName: func -> String { getUnderName() + "_load" }
    getFullName:     func -> String { fullName }
    getUnderName:    func -> String { underName }
    getPathElement:  func -> String { pathElement }

    addFuncType: func (hashName: String, funcType: FuncType) {
        if(!funcTypesMap contains(hashName)) {
            funcTypesMap put(hashName, funcType)
        }
    }

    sanitize: func(str: String) -> String {
        // FIXME this is incomplete, the correct way is actually
        // to replace everything non-alphanumeric with underscores
        result := str replace('/', '_') replace(File separator, '_') replace('-', '_')
        if(!result[0] isAlpha()) result = '_' + result
        result
    }

    addFunction: func (fDecl: FunctionDecl) {
        functions add(fDecl name, fDecl)
    }

    addType: func (tDecl: TypeDecl) {
        types put(tDecl name, tDecl)
        if(tDecl getMeta()) types put(tDecl getMeta() name, tDecl getMeta())
    }

    addOperator: func (oDecl: OperatorDecl) {
        operators add(oDecl)
    }

    addImport: func (imp: Import) {
        imports add(imp)
    }

    addInclude: func (inc: Include) {
        includes add(inc)
    }

    addNamespace: func (nDecl: NamespaceDecl) {
        namespaces put(nDecl getName(), nDecl)
    }
    
    addUse: func (use1: Use) {
        uses add(use1)
    }

    getOperators: func -> List<OperatorDecl> { operators }
    getTypes:     func -> HashMap<String, TypeDecl>  { types }
    getUses:      func -> List<Use>          { uses }

    accept: func (visitor: Visitor) { visitor visitModule(this) }

    getPath: func ~full -> String { path }

    getPath: func (suffix: String) -> String {
        last := (File new(pathElement) name())
        return (last + File separator) + fullName replace('/', File separator) + suffix
    }

    getParentPath: func -> String {
        // FIXME that's sub-optimal
        fileName := pathElement + File separator + fullName + ".ooc"
        parentPath := File new(fileName) parent() path
        return parentPath
    }

    /** return global (e.g. non-namespaced) imports */
    getGlobalImports: func -> List<Import> { imports }

    /** return all imports, including those in namespaces */
    getAllImports: func -> List<Import> {
        if(namespaces isEmpty()) return imports

        list := ArrayList<Import> new()
        list addAll(getGlobalImports())
        for(namespace in namespaces)
            list addAll(namespace getImports())
        return list
    }

    resolveAccess: func (access: VariableAccess) {

        //printf("Looking for %s in %s\n", access toString(), toString())

        // TODO: optimize by returning as soon as the access is resolved
        resolveAccessNonRecursive(access)

        for(imp in getGlobalImports()) {
            imp getModule() resolveAccessNonRecursive(access)
        }

        namespace := namespaces get(access getName())
        if(namespace != null) {
            //printf("resolved access %s to namespace %s!\n", access getName(), namespace toString())
            access suggest(namespace)
        }

    }

    resolveAccessNonRecursive: func (access: VariableAccess) {

        ref := null as Declaration

        for(f in functions) {
            if(f name == access name) {
                access suggest(f)
            }
        }

        ref = types get(access name)
        if(ref != null && access suggest(ref)) {
            return
        }

        body resolveAccess(access)

    }
    
    resolveCall: func (call: FunctionCall) {
        if(call isMember()) {
            return // hmm no member calls for us
        }

        //printf(" >> Looking for function %s in module %s!\n", call name, fullName)
        fDecl : FunctionDecl = null
        fDecl = functions get(call name)
        if(fDecl) {
            //"&&&&&&&& Found fDecl for call %s\n" format(call name) println()
            call suggest(fDecl)
        }

        for(imp in getGlobalImports()) {
            fDecl = imp getModule() functions get(call name)
            if(fDecl) {
                //"&&&&&&&& Found fDecl for call %s in module %s\n" format(call name, imp getModule() fullName) println()
                call suggest(fDecl)
            }
        }
    }

    resolveType: func (type: BaseType) {

        ref : Declaration = null

        ref = types get(type name)
        if(ref != null && type suggest(ref)) {
            return
        }

        for(imp in getGlobalImports()) {
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
        
        {
            response := body resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("response of body = %s\n", response toString())
                finalResponse = response
            }
        }
        
        for(tDecl in types) {
            if(tDecl isResolved()) continue
            response := tDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("response of tDecl %s = %s\n", tDecl toString(), response toString())
                finalResponse = response
            }
        }

        for(fDecl in functions) {
            if(fDecl isResolved()) continue
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("response of fDecl %s = %s\n", fDecl toString(), response toString())
                finalResponse = response
            }
        }

        for(oDecl in operators) {
            if(oDecl isResolved()) continue
            response := oDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) printf("response of oDecl %s = %s\n", oDecl toString(), response toString())
                finalResponse = response
            }
        }

        for(inc in includes) {
            if(inc getVersion() && !inc getVersion() resolve() ok()) return Responses LOOP
        }

        trail pop(this)

        return finalResponse
    }

    toString: func -> String {
        class name + ' ' + fullName
    }

    replace: func (oldie, kiddo: Node) -> Bool { false }

    isScope: func -> Bool { true }

}
