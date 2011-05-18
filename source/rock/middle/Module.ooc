import io/File, text/EscapeSequence
import structs/[HashMap, ArrayList, List, OrderedMultiMap]
import ../frontend/[Token, BuildParams, PathList, AstBuilder]
import ../utils/FileUtils
import Node, FunctionDecl, Visitor, Import, Include, Use, UseDef, TypeDecl,
       FunctionCall, Type, Declaration, VariableAccess, OperatorDecl,
       Scope, NamespaceDecl, BaseType, FuncType, Addon
import tinker/[Response, Resolver, Trail, Errors]

Module: class extends Node {

    // statistics house-keeping
    timesImported := 0
    timesLooped := 0
    
    // true if this module is a dummy only used to get imports!
    dummy := false

    // if this module is out-of-date, 'dead' is set to true.
    dead: Bool { get set }

    // all variants of useful paths
    path, fullName, simpleName, underName, pathElement, oocPath: String
    
    // mostly controls the generation of an implicit main
    main := false

    // 
    types      := OrderedMultiMap<String, TypeDecl> new()
    addons     := ArrayList<Addon> new()
    functions  := OrderedMultiMap<String, FunctionDecl> new()
    operators  := ArrayList<OperatorDecl> new()

    includes   := ArrayList<Include> new()
    imports    := ArrayList<Import> new()
    namespaces := HashMap<String, NamespaceDecl> new()
    uses       := ArrayList<Use> new()

    funcTypesMap := HashMap<String, FuncType> new()

    body       := Scope new()

    lastModified : Long

    params: BuildParams { get set }

    init: func ~module (.fullName, =pathElement, =params, .token) {
        super(token)
        this path = (File separator == '/') ? fullName : fullName replaceAll('/', File separator)
        this oocPath = pathElement + File separator + path + ".ooc"

        // that's a Win32 fix - but I think it's due to an issue in 
        this fullName = fullName replaceAll(File separator, '/')
        idx := this fullName lastIndexOf('/')

        match idx {
            case -1 =>
                simpleName = this fullName clone()
            case =>
                simpleName = this fullName substring(idx + 1)
        }

        underName = sanitize(this fullName)
        
        dead = false
    }

    clone: func -> This {
        raise(This, "Can't clone Module")
        null
    }

    getLoadFuncName: func -> String { getUnderName() + "_load" }
    getFullName:     func -> String { fullName }
    getUnderName:    func -> String { underName }
    getPathElement:  func -> String { pathElement }
    getSourceFolderName: func -> String {
        File new(File new(getPathElement()) getAbsolutePath()) name()
    }

    collectDeps: func -> List<Module> {
        _collectDeps(ArrayList<Module> new())
    }

    _collectDeps: func (list: List<Module>) -> List<Module> {
        list add(this)
        for(imp in getAllImports()) {
            if(imp getModule() == null) continue // what can we do about it? nothing.
            if(!list contains?(imp getModule())) {
                imp getModule() _collectDeps(list)
            }
        }
        list
    }

    addFuncType: func (hashName: String, funcType: FuncType) {
        if(!funcTypesMap contains?(hashName)) {
            funcTypesMap put(hashName, funcType)
        }
    }

    sanitize: func(str: String) -> String {
        assert (str != null)
        assert (str _buffer != null)
        result := str _buffer clone()
        for(i in 0..result length()) {
            current := result[i]
            if(!current alphaNumeric?()) {
                result[i] = '_'
            }
        }
        if(result size > 0 && !result[0] alpha?()) result prepend("_")
        result toString()
    }

    addFunction: func (fDecl: FunctionDecl) {
        // don't add empty-named functions
        if(fDecl name empty?()) return

        hash := TypeDecl hashName(fDecl)
        old := functions get(hash)
        if (old != null) {
            if ((old verzion == fDecl verzion) ||
                (old verzion != null && fDecl verzion != null && old verzion equals?(fDecl verzion))) {

                params errorHandler onError(FunctionRedefinition new(old, fDecl))
                return
            }
        }
        functions put(hash, fDecl)
    }

    addAddon: func (addon: Addon) {
        addons add(addon)
    }

    addType: func (tDecl: TypeDecl) {
        old := types get(tDecl name) as TypeDecl
        if (old != null) {
            if ((old verzion == tDecl verzion) ||
                (old verzion != null && tDecl verzion != null && old verzion equals?(tDecl verzion))) {

                params errorHandler onError(TypeRedefinition new(old, tDecl))
                return
            }
        }

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

    hasNamespace: func (name: String) -> Bool {
        namespaces contains?(name)
    }

    getNamespace: func (name: String) -> NamespaceDecl {
        namespaces get(name)
    }

    addUse: func (uze: Use) {
        uses add(uze)
        if(uze useDef) for(imp in uze useDef imports) {
            // todo: make use imports only findable in the SourcePath specified.
            addImport(Import new(imp, uze token))
        }
    }

    getOperators: func -> List<OperatorDecl> { operators }
    getFunctions: func -> OrderedMultiMap<String, FunctionDecl>  { functions }
    getTypes:     func -> OrderedMultiMap<String, TypeDecl>  { types }
    getUses:      func -> List<Use>          { uses }

    accept: func (visitor: Visitor) { visitor visitModule(this) }

    getPath: func (suffix: String) -> String {
        last := (File new(pathElement) name())
        return (last + File separator) + fullName replaceAll('/', File separator) + suffix
    }

    getOocPath: func -> String {
        oocPath
    }

    /** return global (e.g. non-namespaced) imports */
    getGlobalImports: func -> List<Import> { imports }

    /** return all imports, including those in namespaces */
    getAllImports: func -> List<Import> {
        if(namespaces empty?()) return imports

        list := ArrayList<Import> new()
        list addAll(getGlobalImports())
        for(namespace in namespaces)
            list addAll(namespace getImports())
        return list
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        //printf("Looking for %s in %s\n", access toString(), toString())

        // TODO: optimize by returning as soon as the access is resolved
        resolveAccessNonRecursive(access, res, trail)

        for(imp in getGlobalImports()) {
            imp getModule() resolveAccessNonRecursive(access, res, trail)
        }

        namespace := namespaces get(access getName())
        if(namespace != null) {
            //printf("resolved access %s to namespace %s!\n", access getName(), namespace toString())
            access suggest(namespace)
        }

        0

    }

    resolveAccessNonRecursive: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {

        ref := null as Declaration

        for(f in functions) {
            if(f name == access name) {
                access suggest(f)
            }
        }

        ref = types get(access name)
        if(ref != null && access suggest(ref)) {
            return 0
        }

        // That's actually the only place we want to resolve variables from the
        // body - precisely because they're global
        body resolveAccess(access, res, trail)

        0

    }

    resolveCall: func (call: FunctionCall, res: Resolver, trail: Trail) -> Int {
        if(call isMember()) {
            return 0 // hmm no member calls for us
        }

        resolveCallNonRecursive(call, res, trail)

        for(imp in getGlobalImports()) {
            imp getModule() resolveCallNonRecursive(call, res, trail)
        }

        0
    }

    resolveCallNonRecursive: func (call: FunctionCall, res: Resolver, trail: Trail) {

        //printf(" >> Looking for function %s in module %s!\n", call name, fullName)
        fDecl : FunctionDecl = null
        fDecl = functions get(TypeDecl hashName(call name, call suffix))
        if(fDecl) {
            call suggest(fDecl, res, trail)
        }

        if(!call suffix) for(fDecl in functions) {
            if(fDecl name == call name && (call suffix == null)) {
                if(call debugCondition()) "Suggesting fDecl %s for call %s" printfln(fDecl toString(), call toString())
                call suggest(fDecl, res, trail)
            }
        }

    }

    resolveType: func (type: BaseType, res: Resolver, trail: Trail) -> Int {

        ref : Declaration = null

        ref = types get(type name)
        if(ref != null && type suggest(ref)) {
            return 0
        }

        for(imp in getGlobalImports()) {
            ref = imp getModule() types get(type name)
            if(ref != null && type suggest(ref)) {
                return 0
            }
        }

        0

    }

    /**
     * Parse the imports of this module.
     *
     * If resolver is non-null, it means there's a new import that
     * we expect to add to the resolvers list.
     */
    parseImports: func (resolver: Resolver) {
        for (imp in getAllImports()) {
            if (imp module) continue // nothing to do

            // import paths may contain ".." or relative paths - get it straight first
            (_path, impPath, impElement) := AstBuilder getRealImportPath(imp, this, params)
            if(!impPath) {
                params errorHandler onError(ModuleNotFound new(imp))
                continue
            }
            absolutePath := File new(impPath path) getAbsolutePath()
            // the cache is a key-value store where keys are the absolute paths of modules.
            cached := AstBuilder cache get(absolutePath)
            impLastModified := impPath lastModified()

            // if it's not in the cache or outdated, reparse.
            if(!cached || impLastModified > cached lastModified) {
                if(cached && params veryVerbose) {
                    "%s has been changed, recompiling... (%d vs %d), impPath = %s" printfln(_path, File new(impPath path) lastModified(), cached lastModified, impPath path)
                }

                cached = Module new(_path[0..-5], impElement path, params, nullToken)
                // clean the cache
                AstBuilder cache remove(absolutePath)
                AstBuilder cache put(absolutePath, cached)
                imp setModule(cached)

                cached token = Token new(0, 0, cached)
                if(resolver) resolver addModule(cached)
                
                cached lastModified = impLastModified
                AstBuilder new(impPath path, cached, params)
            }
            
            imp setModule(cached)
            cached parseImports(resolver)
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        finalResponse := Response OK

        trail push(this)

        {
            response := body resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) "response of body = %s" printfln(response toString())
                finalResponse = response
            }
        }

        for(oDecl in operators) {
            if(oDecl isResolved()) continue
            response := oDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) "response of oDecl %s = %s" printfln(oDecl toString(), response toString())
                finalResponse = response
            }
        }

        for(tDecl in types) {
            if(tDecl isResolved()) continue
            response := tDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) "response of tDecl %s = %s" printfln(tDecl toString(), response toString())
                finalResponse = response
            }
        }

        for(addon in addons) {
            response := addon resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) "response of addon %s = %s" printfln(addon toString(), response toString())
                finalResponse = response
            }
        }

        for(fDecl in functions) {
            if(fDecl isResolved()) continue
            response := fDecl resolve(trail, res)
            if(!response ok()) {
                if(res params veryVerbose) "response of fDecl %s = %s" printfln(fDecl toString(), response toString())
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

    isScope: func -> Bool { true }

}

ModuleNotFound: class extends Error {
    imp: Import

    init: func (=imp) {
        super(imp token, "Module not found in sourcepath " + imp path)
    }
}
