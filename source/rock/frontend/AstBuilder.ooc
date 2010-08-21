
import io/File, text/[Buffer, EscapeSequence]

import structs/[ArrayList, List, Stack, HashMap]

import ../utils/FileUtils
import ../frontend/[Token, BuildParams]
import ../middle/tinker/Errors
import ../middle/[FunctionDecl, VariableDecl, TypeDecl, ClassDecl, CoverDecl,
    FunctionCall, StringLiteral, Node, Module, Statement, Include, Import,
    Type, TypeList, Expression, Return, VariableAccess, Cast, If, Else,
    ControlStatement, Comparison, IntLiteral, FloatLiteral, Ternary,
    BinaryOp, BoolLiteral, NullLiteral, Argument, Parenthesis, AddressOf,
    Dereference, Foreach, OperatorDecl, RangeLiteral, UnaryOp, ArrayAccess,
    Match, FlowControl, While, CharLiteral, InterfaceDecl, NamespaceDecl,
    Version, Use, Block, ArrayLiteral, EnumDecl, BaseType, FuncType,
    Declaration, PropertyDecl, CallChain, Tuple, Addon]

nq_parse: extern proto func (AstBuilder, Char*) -> Int

// reserved C99 keywords
reservedWords := ["auto", "int", "long", "char", "register", "short", "do",
                  "sizeof", "double", "struct", "switch", "typedef", "union",
                  "unsigned", "signed", "goto", "enum", "const"]
reservedHashs := computeReservedHashs(reservedWords)

ReservedKeywordError: class extends Error {
    init: super func ~tokenMessage
}

computeReservedHashs: func (words: String[]) -> ArrayList<Int> {
    list := ArrayList<Int> new()
    for(i in 0..words length) {
        word := words[i]
        list add(ac_X31_hash(word))
    }
    list
}

AstBuilder: class {

    cache := static HashMap<String, Module> new()

    langImports : List<String>

    params: BuildParams
    modulePath: String
    module: Module
    stack: Stack<Object>
    versionStack: Stack<VersionSpec>

    tokenPos : Int*

    init: func (=modulePath, =module, =params) {
        first := static true

        if(params verbose) {
            if(!first) "                                                                             \r" print()
            "Parsing %s" printf(modulePath)
        }
        cache put(File new(modulePath) getAbsolutePath(), module)

        stack = Stack<Object> new()
        stack push(module)
        versionStack = Stack<VersionSpec> new()

        if(params includeLang && !module fullName startsWith?("/")) {
            addLangImports()
        }

        first = false
        result := nq_parse(this, modulePath)
        if(result == -1) {
            Exception new(This, "File " +modulePath + " not found") throw()
        }

    }

    addLangImports: func {

        langImports : static List<String> = null

        if(langImports == null) {
            langImports = ArrayList<String> new()
            paths := params sourcePath getRelativePaths("lang")
            for(path in paths) {
                if(path endsWith?(".ooc")) {
                    impName := path substring(0, path length() - 4) replace(File separator, '/')
                    langImports add(impName)
                }
            }
        }

        for(impName in langImports) {
            if(impName != module fullName) {
                //printf("Adding import %s to %s\n", impName, module fullName)
                module addImport(Import new(impName, module token))
            }
        }

    }

    /**
     * Turn import paths like "../frontend/AstBuilder" into "/opt/ooc/rock/source/rock/frontend/AstBuilder"
     */
    getRealImportPath: static func (imp: Import, module: Module, params: BuildParams, path: String@, impPath, impElement: File@) -> File {

        path = FileUtils resolveRedundancies(imp path + ".ooc")
        impElement = params sourcePath getElement(path)
        impPath    = params sourcePath getFile(path)
        if(impPath == null) {
            parent := File new(module getPath()) parent()
            if(parent != null) {
                path = FileUtils resolveRedundancies(parent path + File separator + imp path + ".ooc")
                impElement = params sourcePath getElement(path)
                impPath    = params sourcePath getFile(path)
            }
        }
        return impPath

    }

    printCache: static func {
        printf("==== Cache ====\n")
        for(key in cache getKeys()) {
            printf("cache %s => %s\n", key, cache get(key) fullName)
        }
        printf("===============\n")
    }

    error: func (errorID: Int, message: String, index: Int) {
        params errorHandler onError(SyntaxError new(Token new(index, 1, module), message))
    }

    onUse: unmangled(nq_onUse) func (identifier: String) {
        module addUse(Use new(identifier, params, token()))
    }

    onInclude: unmangled(nq_onInclude) func (path: String) {
        mode: IncludeMode
        if(path startsWith?("./")) {
            mode = IncludeModes LOCAL
            path = path substring(2) // remove ./ from path
        }
        else {
            mode = IncludeModes PATHY
        }

        inc := Include new(path, mode)
        module addInclude(inc)
        inc setVersion(getVersion())
    }

    onIncludeDefine: unmangled(nq_onIncludeDefine) func (name, value: String) {
        module includes last() addDefine(Define new(name clone(), value clone()))
    }

    onImport: unmangled(nq_onImport) func (path, name: String) {
        module addImport(Import new(path empty?() ? name : path + name, token()))
    }

    onImportNamespace: unmangled(nq_onImportNamespace) func (namespace: String, quantity: Int) {
        nDecl: NamespaceDecl
        if(!module hasNamespace(namespace)) {
            nDecl = NamespaceDecl new(namespace clone())
            module addNamespace(nDecl)
        } else {
            nDecl = module getNamespace(namespace)
        }
        peek(Module) // ensure we're a at root level
        for(i in 0..quantity) {
            nDecl addImport(module getGlobalImports() last())
            module getGlobalImports() removeAt(module getGlobalImports() lastIndex()) // no longer a global import
        }
    }

    /*
     * Addons
     */
    onExtendStart: unmangled(nq_onExtendStart) func (baseType: Type, doc: String) {
        addon := Addon new(baseType, token())
        addon doc = doc
        stack push(addon)
    }

    onExtendEnd: unmangled(nq_onExtendEnd) func -> Addon {
        module addAddon(pop(Addon))
    }

    /*
     * Covers
     */

    onCoverStart: unmangled(nq_onCoverStart) func (name, doc: String) {
        cDecl := CoverDecl new(name clone(), token())
        cDecl setVersion(getVersion())
        cDecl doc = doc
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }

    onCoverExtern: unmangled(nq_onCoverExtern) func (externName: String) {
        peek(CoverDecl) setExternName(externName clone())
    }

    onCoverFromType: unmangled(nq_onCoverFromType) func (type: Type) {
        peek(CoverDecl) setFromType(type)
    }

    onCoverExtends: unmangled(nq_onCoverExtends) func (superType: Type) {
        peek(CoverDecl) setSuperType(superType)
    }

    onCoverImplements: unmangled(nq_onCoverImplements) func (interfaceType: Type) {
        peek(CoverDecl) addInterface(interfaceType)
    }

    onCoverEnd: unmangled(nq_onCoverEnd) func {
        pop(CoverDecl)
    }

    /*
     * Enums
     */

    onEnumStart: unmangled(nq_onEnumStart) func (name, doc: String) {
        eDecl := EnumDecl new(name clone(), token())
        eDecl setVersion(getVersion())
        eDecl module = module
        eDecl doc = doc
        module addType(eDecl)
        stack push(eDecl)
    }

    onEnumExtern: unmangled(nq_onEnumExtern) func (externName: String) {
        peek(EnumDecl) setExternName(externName clone())
    }

    onEnumFromType: unmangled(nq_onEnumFromType) func (fromType: Type) {
        peek(EnumDecl) setFromType(fromType)
    }

    onEnumIncrementExpr: unmangled(nq_onEnumIncrementExpr) func (oper: Char, step: IntLiteral) {
        peek(EnumDecl) setIncrement(oper, step value)
    }

    onEnumElementStart: unmangled(nq_onEnumElementStart) func (name, doc: String) {
        element := EnumElement new(peek(EnumDecl) getInstanceType(), name clone(), token())
        element doc = doc
        stack push(element)
    }

    onEnumElementValue: unmangled(nq_onEnumElementValue) func (value: Expression) {
        peek(EnumElement) setValue(value)
    }

    onEnumElementExtern: unmangled(nq_onEnumElementExtern) func (externName: String) {
        peek(EnumElement) setExternName(externName clone())
    }

    onEnumElementEnd: unmangled(nq_onEnumElementEnd) func {
        element := pop(EnumElement)
        peek(EnumDecl) addElement(element)
    }

    onEnumEnd: unmangled(nq_onEnumEnd) func {
        pop(EnumDecl)
    }

    /*
     * Classes
     */

    onClassStart: unmangled(nq_onClassStart) func (name, doc: String) {
        cDecl := ClassDecl new(name clone(), token())
        cDecl setVersion(getVersion())
        cDecl doc = doc
        cDecl module = module
        module addType(cDecl)
        stack push(cDecl)
    }

    onClassExtends: unmangled(nq_onClassExtends) func (superType: Type) {
        peek(ClassDecl) setSuperType(superType)
    }

    onClassImplements: unmangled(nq_onClassImplements) func (interfaceType: Type) {
        peek(ClassDecl) addInterface(interfaceType)
    }

    onClassAbstract: unmangled(nq_onClassAbstract) func {
        peek(ClassDecl) isAbstract = true
    }

    onClassFinal: unmangled(nq_onClassFinal) func {
        peek(ClassDecl) isFinal = true
    }

    onClassBody: unmangled(nq_onClassBody) func {
        peek(ClassDecl) addDefaultInit()    }

    onClassEnd: unmangled(nq_onClassEnd) func {
        pop(ClassDecl)
    }

    /*
     * Version blocks
     */

    onVersionName: unmangled(nq_onVersionName) func (name: String) -> VersionSpec {
        VersionName new(name clone(), token())
    }

    onVersionNegation: unmangled(nq_onVersionNegation) func (spec: VersionSpec) -> VersionSpec {
        VersionNegation new(spec, token())
    }

    onVersionAnd: unmangled(nq_onVersionAnd) func (specLeft, specRight: VersionSpec) -> VersionSpec {
        VersionAnd new(specLeft, specRight, token())
    }

    onVersionOr: unmangled(nq_onVersionOr) func (specLeft, specRight: VersionSpec) -> VersionSpec {
        VersionOr new(specLeft, specRight, token())
    }

    onVersionStart: unmangled(nq_onVersionStart) func (spec: VersionSpec) {
        object := peek(Object)
        if(object instanceOf?(Module)) {
            versionStack push(spec)
        } else {
            vb := VersionBlock new(spec, token())
            stack push(vb)
        }
    }

    onVersionEnd: unmangled(nq_onVersionEnd) func -> VersionBlock {
        object := peek(Object)
        if(object instanceOf?(Module)) {
            versionStack pop()
        } else {
            vb := pop(VersionBlock)
            return vb
        }
        return null
    }

    /*
     * Interfaces
     */

    onInterfaceStart: unmangled(nq_onInterfaceStart) func (name, doc: String) {
        iDecl := InterfaceDecl new(name clone(), token())
        iDecl setVersion(getVersion())
        iDecl doc = doc
        iDecl module = module
        module addType(iDecl)
        stack push(iDecl)
    }

    onInterfaceExtends: unmangled(nq_onInterfaceExtends) func (superType: Type) {
        peek(InterfaceDecl) setSuperType(superType)
    }

    onInterfaceEnd: unmangled(nq_onInterfaceEnd) func {
        pop(InterfaceDecl)
    }

    onTypeAccess: unmangled(nq_onTypeAccess) func (t: Type) -> TypeAccess {
        TypeAccess new(t, t token)
    }

    /*
     * Variable declarations
     */

    onVarDeclStart: unmangled(nq_onVarDeclStart) func {
        stack push(Stack<VariableDecl> new())
    }

    onVarDeclName: unmangled(nq_onVarDeclName) func (name, doc: String) {
        vDecl := VariableDecl new(null, name clone(), token())
        vDecl doc = doc
        peek(Stack<VariableDecl>) push(vDecl)
    }

    onVarDeclTuple: unmangled(nq_onVarDeclTuple) func (tuple: Tuple) {
        peek(Stack<VariableDecl>) push(VariableDeclTuple new(null as Type, tuple, token()))
    }

    onVarDeclExtern: unmangled(nq_onVarDeclExtern) func (externName: String) {
        vars := peek(Stack<VariableDecl>)
        if(externName empty?()) {
            for(var in vars) var setExternName("")
        } else {
            if(vars size() != 1) {
                params errorHandler onError(SyntaxError new(token(), "Trying to set an extern name on several variables at once!"))
            }
            vars peek() setExternName(externName clone())
        }
    }

    onVarDeclUnmangled: unmangled(nq_onVarDeclUnmangled) func (unmangledName: String) {
        vars := peek(Stack<VariableDecl>)
        if(unmangledName empty?()) {
            for(var in vars) var setUnmangledName("")
        } else {
            if(vars size() != 1) {
                params errorHandler onError(SyntaxError new(token(), "Trying to set an unmangled name on several variables at once!"))
            }
            vars peek() setUnmangledName(unmangledName clone())
        }
    }

    onVarDeclExpr: unmangled(nq_onVarDeclExpr) func (expr: Expression) {
        peek(Stack<VariableDecl>) peek() setExpr(expr)
    }

    onVarDeclStatic: unmangled(nq_onVarDeclStatic) func {
        for(vd: VariableDecl in peek(Stack<VariableDecl>)) {
            vd setStatic(true)
        }
    }

    onVarDeclProto: unmangled(nq_onVarDeclProto) func {
        for(vd: VariableDecl in peek(Stack<VariableDecl>)) {
            vd setProto(true)
        }
    }

    onVarDeclConst: unmangled(nq_onVarDeclConst) func {
        for(vd: VariableDecl in peek(Stack<VariableDecl>)) {
            vd setConst(true)
        }
    }

    onVarDeclType: unmangled(nq_onVarDeclType) func (type: Type) {
        for(vd: VariableDecl in peek(Stack<VariableDecl>)) {
            vd type = type
        }
    }

    onVarDeclEnd: unmangled(nq_onVarDeclEnd) func -> Object {
        stack := pop(Stack<VariableDecl>)
        if(stack size() == 1) return stack peek() as Object
        // FIXME: Better detection to avoid 'stack' being passed as a Statement to, say, an If
        return stack as Object
    }

    gotVarDecl: func (vd: VariableDecl) {
        hash := ac_X31_hash(vd getName())
        idx := reservedHashs indexOf(hash)
        if(idx != -1) {
            // same hash? compare length and then full-string comparison
            word := reservedWords[idx]
            if(word length() == vd getName() length() && word == vd getName()) {
                params errorHandler onError(ReservedKeywordError new(vd token, "%s is a reserved C99 keyword, you can't use it in a variable declaration" format(vd getName())))
            }
        }

        node : Node = stack peek()
        //printf("[gotVarDecl] Got variable decl %s, and parent is a %s\n", vd toString(), node class name)
        if(node instanceOf?(TypeDecl)) {
            tDecl := node as TypeDecl
            tDecl addVariable(vd)
        } else if(node instanceOf?(List)) {
            vd isArg = true
            node as List<Node> add(vd)
        } else {
            //printf("[gotVarDecl] Parent is a %s, don't know what to do, calling gotStatement()\n", node class name)
            gotStatement(vd)
        }
    }

    /*
     * Properties
     */

    onPropertyDeclStart: unmangled(nq_onPropertyDeclStart) func (name: String) {
        stack push(PropertyDecl new(null, name clone(), token()))
    }

    onPropertyDeclStatic: unmangled(nq_onPropertyDeclStatic) func {
        peek(PropertyDecl) setStatic(true)
    }

    onPropertyDeclType: unmangled(nq_onPropertyDeclType) func (type: Type) {
        peek(PropertyDecl) type = type
    }

    onPropertyDeclGetterStart: unmangled(nq_onPropertyDeclGetterStart) func {
        getter := FunctionDecl new("", token())
        stack push(getter)
    }

    onPropertyDeclGetterEnd: unmangled(nq_onPropertyDeclGetterEnd) func {
        getter := pop(FunctionDecl)
        // getter has 0 statements and isn't extern? use default getter
        if(getter body size() == 0 && !getter isExtern()) {
            peek(PropertyDecl) setDefaultGetter()
        } else {
            peek(PropertyDecl) setGetter(getter)
        }
    }

    onPropertyDeclSetterStart: unmangled(nq_onPropertyDeclSetterStart) func {
        setter := FunctionDecl new("", token())
        stack push(setter)
    }

    onPropertyDeclSetterArgument: unmangled(nq_onPropertyDeclSetterArgument) func (name: String, conventional: Bool) {
        arg: Argument = match conventional {
            case true => Argument new(null, name clone(), token())
            case false => AssArg new(name clone(), token())
        }
        peek(FunctionDecl) args add(arg)
    }

    onPropertyDeclSetterEnd: unmangled(nq_onPropertyDeclSetterEnd) func {
        setter := pop(FunctionDecl)
        // setter has 0 statements and isn't extern? use default setter
        if(setter body size() == 0 && !setter isExtern()) {
            peek(PropertyDecl) setDefaultSetter()
        } else {
            peek(PropertyDecl) setSetter(setter)
        }
    }

    onPropertyDeclEnd: unmangled(nq_onPropertyDeclEnd) func -> PropertyDecl {
        decl := pop(PropertyDecl)
        node := peek(TypeDecl)
        node addVariable(decl)
        decl
    }

    /*
     * Types
     */

    onTypeNew: unmangled(nq_onTypeNew) func (name: String) -> Type {
        BaseType new(name clone() trim(), token())
    }

    onTypePointer: unmangled(nq_onTypePointer) func (type: Type) -> Type {
        PointerType new(type, token())
    }

    onTypeReference: unmangled(nq_onTypeReference) func (type: Type) -> Type {
        ReferenceType new(type, token())
    }

    onTypeBrackets: unmangled(nq_onTypeBrackets) func (type: Type, inner: Expression) -> Type {
        ArrayType new(type, inner, token())
    }

    onTypeGenericArgument: unmangled(nq_onTypeGenericArgument) func (type: Type, typeInner: Type) {
        type addTypeArg(VariableAccess new(typeInner, token()))
    }

    onTypeList: unmangled(nq_onTypeList) func -> TypeList {
        TypeList new(token())
    }

    onTypeListElement: unmangled(nq_onTypeListElement) func (list: TypeList, element: Type) {
        list types add(element)
    }

    /*
     * Function types
     */

    onFuncTypeNew: unmangled(nq_onFuncTypeNew) func -> FuncType {
        f := FuncType new(token())
        f isClosure = true
        f
    }

    onFuncTypeArgument: unmangled(nq_onFuncTypeArgument) func (f: FuncType, argType: Type) {
        f argTypes add(argType)
    }

    onFuncTypeVarArg: unmangled(nq_onFuncTypeVarArg) func (f: FuncType) {
        f varArg = true
    }

    onFuncTypeReturnType: unmangled(nq_onFuncTypeReturnType) func (f: FuncType, returnType: Type) {
        f returnType = returnType
    }

    /*
     * Operator overloads
     */

    onOperatorStart: unmangled(nq_onOperatorStart) func (symbol: String) {
        oDecl := OperatorDecl new(symbol clone() trim(), token())
        fDecl := FunctionDecl new("", token())
        oDecl setFunctionDecl(fDecl)
        stack push(oDecl)
        stack push(fDecl)
    }

    onOperatorEnd: unmangled(nq_onOperatorEnd) func {
        oDecl := pop(OperatorDecl)
        peek(Module) addOperator(oDecl)
    }

    /*
     * Functions
     */

    onFunctionStart: unmangled(nq_onFunctionStart) func (name, doc: String) {
        fDecl := FunctionDecl new(name clone(), token())
        fDecl setVersion(getVersion())
        fDecl doc = doc
        stack push(fDecl)
    }

    onFunctionExtern: unmangled(nq_onFunctionExtern) func (externName: String) {
        peek(FunctionDecl) setExternName(externName clone())
    }

    onFunctionUnmangled: unmangled(nq_onFunctionUnmangled) func (unmangledName: String) {
        peek(FunctionDecl) setUnmangledName(unmangledName clone())
    }

    onFunctionAbstract: unmangled(nq_onFunctionAbstract) func {
        peek(FunctionDecl) isAbstract = true
    }
    onFunctionThisRef: unmangled(nq_onFunctionThisRef) func {
        peek(FunctionDecl) isThisRef = true
    }
    onFunctionStatic: unmangled(nq_onFunctionStatic) func {
        peek(FunctionDecl) isStatic = true
    }
    onFunctionInline: unmangled(nq_onFunctionInline) func {
        peek(FunctionDecl) isInline = true
    }

    onFunctionFinal: unmangled(nq_onFunctionFinal) func {
        peek(FunctionDecl) isFinal = true
    }

    onFunctionProto: unmangled(nq_onFunctionProto) func {
        peek(FunctionDecl) isProto = true
    }

    onFunctionSuper: unmangled(nq_onFunctionSuper) func {
        peek(FunctionDecl) isSuper = true
    }

    onFunctionSuffix: unmangled(nq_onFunctionSuffix) func (suffix: String) {
        peek(FunctionDecl) suffix = suffix clone()
    }

    onFunctionArgsStart: unmangled(nq_onFunctionArgsStart) func {
        stack push(peek(FunctionDecl) args)
    }

    onFunctionArgsEnd: unmangled(nq_onFunctionArgsEnd) func {
        pop(ArrayList<Argument>)
    }

    onFunctionReturnType: unmangled(nq_onFunctionReturnType) func (type: Type) {
        peek(FunctionDecl) returnType = type
    }

    onFunctionBody: unmangled(nq_onFunctionBody) func {
        peek(FunctionDecl) hasBody = true
    }

    onFunctionEnd: unmangled(nq_onFunctionEnd) func -> FunctionDecl {
        fDecl := pop(FunctionDecl)
        node : Node = stack peek()
        if(node == module) {
            module addFunction(fDecl)
        } else if(node instanceOf?(TypeDecl)) {
            tDecl := node as TypeDecl
            tDecl addFunction(fDecl)
        } else if(node instanceOf?(Addon)) {
            addon := node as Addon
            addon addFunction(fDecl)
        } else {
            //printf("^^^^^^^^ Unexpected function %s (peek is a %s)\n", fDecl name, node class name)
        }
        return fDecl
    }

    /*
     * Function calls
     */

    onFunctionCallStart: unmangled(nq_onFunctionCallStart) func (name: String) {
        stack push(FunctionCall new(name clone(), token()))
    }

    onFunctionCallSuffix: unmangled(nq_onFunctionCallSuffix) func (suffix: String) {
        peek(FunctionCall) setSuffix(suffix clone())
    }

    onFunctionCallArg: unmangled(nq_onFunctionCallArg) func (expr: Expression) {
        peek(FunctionCall) args add(expr)
    }

    onFunctionCallEnd: unmangled(nq_onFunctionCallEnd) func -> FunctionCall {
        pop(FunctionCall)
    }

    onFunctionCallExpr: unmangled(nq_onFunctionCallExpr) func (call: FunctionCall, expr: Expression) {
        call expr = expr
    }

    onFunctionCallCombo: unmangled(nq_onFunctionCallCombo) func (call: FunctionCall, expr: Expression) {
        name := call generateTempName("comboRoot")
        call setName(name)
        vDecl := VariableDecl new(null, name, expr, expr token)
        onStatement(vDecl)
    }

    onFunctionCallChain: unmangled(nq_onFunctionCallChain) func (expr: Expression, call: FunctionCall) -> CallChain {
        if(expr instanceOf?(CallChain)) {
            chain := expr as CallChain
            //printf("Adding %s to existing callchain %s\n", call toString(), chain toString())
            chain calls add(call)
            return chain
        } else {
            //printf("Creating new call chain with expr %s and call %s\n", expr toString(), call toString())
            return CallChain new(expr, call)
        }
    }

    /*
     * Literals
     */

    onArrayLiteralStart: unmangled(nq_onArrayLiteralStart) func {
        stack push(ArrayLiteral new(token()))
    }

    onArrayLiteralEnd: unmangled(nq_onArrayLiteralEnd) func -> ArrayLiteral {
        pop(ArrayLiteral)
    }

    onTupleStart: unmangled(nq_onTupleStart) func {
        stack push(Tuple new(token()))
    }

    onTupleEnd: unmangled(nq_onTupleEnd) func -> Tuple {
        pop(Tuple)
    }

    onStringLiteral: unmangled(nq_onStringLiteral) func (text: String) -> StringLiteral {
        StringLiteral new(text clone() replace("\n", "\\n") replace("\t", "\\t"), token())
    }

    onCharLiteral: unmangled(nq_onCharLiteral) func (value: String) -> CharLiteral {
        CharLiteral new(value clone(), token())
    }

    // statement
    onStatement: unmangled(nq_onStatement) func (stmt: Statement) {
        if(stmt instanceOf?(VariableDecl)) {
            //printf("[onStatement] stmt %s is a VariableDecl, calling gotVarDecl\n", stmt toString())
            gotVarDecl(stmt as VariableDecl)
            return
        } else if(stmt instanceOf?(Stack<VariableDecl>)) {
            stack : Stack<VariableDecl> = stmt
            if(stack T inheritsFrom?(VariableDecl)) {
                //printf("[onStatement] stmt is a Stack<VariableDecl>, calling gotVarDecl on each of'em\n")
                for(vd in stack) {
                    //printf("[onStatement] among em, %s\n", vd toString())
                    gotVarDecl(vd)
                }
                return
            }
        }

        gotStatement(stmt)
    }

    gotStatement: func (stmt: Statement) {
        node := peek(Node)

        match {
            case node instanceOf?(FunctionDecl) =>
                fDecl := node as FunctionDecl
                fDecl body add(stmt)
            case node instanceOf?(ControlStatement) =>
                cStmt := node as ControlStatement
                cStmt body add(stmt)
            case node instanceOf?(ArrayAccess) =>
                aa := node as ArrayAccess
                if(!stmt instanceOf?(Expression)) {
                    params errorHandler onError(SyntaxError new(stmt token, "Expected an expression here, not a statement!"))
                }
                aa indices add(stmt as Expression)
            case node instanceOf?(Module) =>
                if(stmt instanceOf?(VariableDecl)) {
                    vd := stmt as VariableDecl
                    vd setGlobal(true)
                }
                module := node as Module

                spec := getVersion()
                if(spec != null) {
                    vb := VersionBlock new(spec, token())
                    vb getBody() add(stmt)
                    module body add(vb)
                } else {
                    module body add(stmt)
                }
            case node instanceOf?(ClassDecl) =>
                cDecl := node as ClassDecl
                fDecl := cDecl lookupFunction(ClassDecl DEFAULTS_FUNC_NAME, "")
                if(fDecl == null) {
                    fDecl = FunctionDecl new(ClassDecl DEFAULTS_FUNC_NAME, cDecl token)
                    cDecl addFunction(fDecl)
                }
                fDecl getBody() add(stmt)
            case node instanceOf?(ArrayLiteral) =>
                arrayLit := node as ArrayLiteral
                if(!stmt instanceOf?(Expression)) {
                    params errorHandler onError(SyntaxError new(stmt token, "Expected an expression here, not a statement!"))
                }
                arrayLit getElements() add(stmt as Expression)
            case node instanceOf?(Tuple) =>
                tuple := node as Tuple
                if(!stmt instanceOf?(Expression)) {
                    params errorHandler onError(SyntaxError new(stmt token, "Expected an expression here, not a statement!"))
                }
                tuple getElements() add(stmt as Expression)
            case =>
                printf("[gotStatement] Got a %s, don't know what to do with it, parent = %s\n", stmt toString(), node class name)
        }
    }

    onArrayAccessStart: unmangled(nq_onArrayAccessStart) func (array: Expression) {
        stack push(ArrayAccess new(array, token()))
    }

    onArrayAccessEnd: unmangled(nq_onArrayAccessEnd) func () -> ArrayAccess {
        pop(ArrayAccess)
    }

    // return
    onReturn: unmangled(nq_onReturn) func (expr: Expression) -> Return {
        Return new(expr, token())
    }

    // variable access
    onVarAccess: unmangled(nq_onVarAccess) func (expr: Expression, name: String) -> VariableAccess {
        return VariableAccess new(expr, name clone(), token())
    }

    // cast
    onCast: unmangled(nq_onCast) func (expr: Expression, type: Type) -> Cast {
        return Cast new(expr, type, token())
    }

    // block {}
    onBlockStart: unmangled(nq_onBlockStart) func {
        stack push(Block new(token()))
    }

    onBlockEnd: unmangled(nq_onBlockEnd) func -> Block {
        pop(Block)
    }

    // if
    onIfStart: unmangled(nq_onIfStart) func (condition: Expression) {
        stack push(If new(condition, token()))
    }

    onIfEnd: unmangled(nq_onIfEnd) func -> If {
        pop(If)
    }

    // else
    onElseStart: unmangled(nq_onElseStart) func {
        stack push(Else new(token()))
    }

    onElseEnd: unmangled(nq_onElseEnd) func -> Else {
        pop(Else)
    }

    // foreach
    onForeachStart: unmangled(nq_onForeachStart) func (decl, collec: Expression) {
        if(decl instanceOf?(Stack)) {
            decl = decl as Stack<VariableDecl> pop()
        }
        stack push(Foreach new(decl, collec, token()))
    }

    onForeachEnd: unmangled(nq_onForeachEnd) func -> Foreach {
        pop(Foreach)
    }

    // while
    onWhileStart: unmangled(nq_onWhileStart) func (condition: Expression) {
        stack push(While new(condition, token()))
    }

    onWhileEnd: unmangled(nq_onWhileEnd) func -> While {
        pop(While)
    }

    /*
     * Arguments
     */
    onVarArg: unmangled(nq_onVarArg) func {
        peek(List<Node>) add(VarArg new(token()))
    }

    onTypeArg: unmangled(nq_onTypeArg) func (type: Type) {
        // TODO: add check for extern function (TypeArgs are illegal in non-extern functions.)
        peek(List<Node>) add(Argument new(type, "", token()))
    }

    onDotArg: unmangled(nq_onDotArg) func (name: String) {
        // TODO: add check for member function
        peek(List<Node>) add(DotArg new(name clone(), token()))
    }

    onAssArg: unmangled(nq_onAssArg) func (name: String) {
        // TODO: add check for member function
        peek(List<Node>) add(AssArg new(name clone(), token()))
    }

    /*
     * Match & case
     */
    onMatchStart: unmangled(nq_onMatchStart) func {
        stack push(Match new(token()))
    }

    onMatchExpr: unmangled(nq_onMatchExpr) func (v:Expression) {
        peek(Match) setExpr(v)
    }

    onMatchEnd: unmangled(nq_onMatchEnd) func -> Match {
        pop(Match)
    }

    onCaseStart: unmangled(nq_onCaseStart) func {
        stack push(Case new(token()))
    }

    onCaseExpr: unmangled(nq_onCaseExpr) func (v:Expression) {
        peek(Case) setExpr(v)
    }

    onCaseEnd: unmangled(nq_onCaseEnd) func {
        caze := pop(Case)
        peek(Match) addCase(caze)
    }

    onBreak: unmangled(nq_onBreak) func -> FlowControl {
        FlowControl new(FlowActions _break, token())
    }

    onContinue: unmangled(nq_onContinue) func -> FlowControl {
        FlowControl new(FlowActions _continue, token())
    }

    onEquals: unmangled(nq_onEquals) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType equal, token())
    }

    onNotEquals: unmangled(nq_onNotEquals) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType notEqual, token())
    }

    onLessThan: unmangled(nq_onLessThan) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType smallerThan, token())
    }

    onMoreThan: unmangled(nq_onMoreThan) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType greaterThan, token())
    }

    onCmp: unmangled(nq_onCmp) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType compare, token())
    }

    onLessThanOrEqual: unmangled(nq_onLessThanOrEqual) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType smallerOrEqual, token())
    }
    onMoreThanOrEqual: unmangled(nq_onMoreThanOrEqual) func (left, right: Expression) -> Comparison {
        Comparison new(left, right, CompType greaterOrEqual, token())
    }

    onDecLiteral: unmangled(nq_onDecLiteral) func (value: String) -> IntLiteral {
        IntLiteral new(value replace("_", "") toLLong(), token())
    }

    onOctLiteral: unmangled(nq_onOctLiteral) func (value: String) -> IntLiteral {
        IntLiteral new(value replace("_", "") substring(2) toLLong(8), token())
    }

    onBinLiteral: unmangled(nq_onBinLiteral) func (value: String) -> IntLiteral {
        IntLiteral new(value replace("_", "") substring(2) toLLong(2), token())
    }

    onHexLiteral: unmangled(nq_onHexLiteral) func (value: String) -> IntLiteral {
        IntLiteral new(value replace("_", "") toLLong(16), token())
    }

    onFloatLiteral: unmangled(nq_onFloatLiteral) func (value: String) -> FloatLiteral {
        FloatLiteral new(value replace("_", "") toFloat(), token())
    }

    onBoolLiteral: unmangled(nq_onBoolLiteral) func (value: Bool) -> BoolLiteral {
        BoolLiteral new(value, token())
    }

    onNull: unmangled(nq_onNull) func -> NullLiteral {
        NullLiteral new(token())
    }

    onTernary: unmangled(nq_onTernary) func (condition, ifTrue, ifFalse: Expression) -> Ternary {
        Ternary new(condition, ifTrue, ifFalse, token())
    }

    onAssignAdd: unmangled(nq_onAssignAdd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType addAss, token())
    }

    onAssignSub: unmangled(nq_onAssignSub) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType subAss, token())
    }

    onAssignMul: unmangled(nq_onAssignMul) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType mulAss, token())
    }

    onAssignDiv: unmangled(nq_onAssignDiv) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType divAss, token())
    }

    onAssignAnd: unmangled(nq_onAssignAnd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType bAndAss, token())
    }

    onAssignOr: unmangled(nq_onAssignOr) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType bOrAss, token())
    }

    onAssignXor: unmangled(nq_onAssignXor) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType bXorAss, token())
    }

    onAssign: unmangled(nq_onAssign) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType ass, token())
    }

    onAssignLeftShift: unmangled(nq_onAssignLeftShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType lshiftAss, token())
    }

    onAssignRightShift: unmangled(nq_onAssignRightShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType rshiftAss, token())
    }

    onAdd: unmangled(nq_onAdd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType add, token())
    }

    onSub: unmangled(nq_onSub) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType sub, token())
    }

    onMod: unmangled(nq_onMod) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType mod, token())
    }

    onMul: unmangled(nq_onMul) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType mul, token())
    }

    onDiv: unmangled(nq_onDiv) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType div, token())
    }

    onRangeLiteral: unmangled(nq_onRangeLiteral) func (left, right: Expression) -> RangeLiteral {
        RangeLiteral new(left, right, token())
    }

    onBinaryLeftShift: unmangled(nq_onBinaryLeftShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType lshift, token())
    }

    onBinaryRightShift: unmangled(nq_onBinaryRightShift) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType rshift, token())
    }

    onLogicalOr: unmangled(nq_onLogicalOr) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType or, token())
    }

    onLogicalAnd: unmangled(nq_onLogicalAnd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType and, token())
    }

    onBinaryOr: unmangled(nq_onBinaryOr) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType bOr, token())
    }

    onBinaryXor: unmangled(nq_onBinaryXor) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType bXor, token())
    }

    onBinaryAnd: unmangled(nq_onBinaryAnd) func (left, right: Expression) -> BinaryOp {
        BinaryOp new(left, right, OpType bAnd, token())
    }

    onLogicalNot: unmangled(nq_onLogicalNot) func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpType logicalNot, token())
    }

    onBinaryNot: unmangled(nq_onBinaryNot) func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpType binaryNot, token())
    }

    onUnaryMinus: unmangled(nq_onUnaryMinus) func (inner: Expression) -> UnaryOp {
        UnaryOp new(inner, UnaryOpType unaryMinus, token())
    }

    onParenthesis: unmangled(nq_onParenthesis) func (inner: Expression) -> Parenthesis {
        Parenthesis new(inner, token())
    }

    onGenericArgument: unmangled(nq_onGenericArgument) func (name: String) {
        node := peek(Node)

        //printf("======= Got generic argument %s, and node is a %s\n", name, node class name)
        vDecl := VariableDecl new(BaseType new("Class", token()), name clone(), token())

        done := false
        if(node instanceOf?(Declaration)) {
            done = node as Declaration addTypeArg(vDecl)
        }

        if(!done) params errorHandler onError(InternalError new(token(), "Unexpected type argument in a %s declaration!" format(node class name)))

    }

    onAddressOf: unmangled(nq_onAddressOf) func (inner: Expression) -> AddressOf {
        AddressOf new(inner, inner token)
    }

    onDereference: unmangled(nq_onDereference) func (inner: Expression) -> Dereference {
        Dereference new(inner, token())
    }

    token: func -> Token {
        Token new(tokenPos[0], tokenPos[1], module)
    }

    peek: func <T> (T: Class) -> T {
        node := stack peek() as Node
        if(!node instanceOf?(T)) {
            params errorHandler onError(InternalError new(token(), "Should've peek'd a %s, but peek'd a %s. Stack = %s" format(T name, node class name, stackRepr())))
        }
        return node
    }

    pop: func <T> (T: Class) -> T {
        node := stack pop() as Node
        if(!node instanceOf?(T)) {
            params errorHandler onError(InternalError new(token(), "Should've pop'd a %s, but pop'd a %s. Stack = %s" format(T name, node class name, stackRepr())))
        }
        return node
    }

    stackRepr: func -> String {
        sb := Buffer new()
        for(e in stack) {
            sb append(e class name). append(", ")
        }
        sb toString()
    }

    getVersion: func -> VersionSpec {
        spec := null as VersionSpec

        for(v in versionStack) {
            if(spec) {
                spec = VersionAnd new(spec, v, spec token)
            } else {
                spec = v
            }
        }

        return spec
    }

}

// position in stream handling
nq_setTokenPositionPointer: unmangled func (this: AstBuilder, tokenPos: Int*) { this tokenPos = tokenPos }

// string handling
nq_StringClone: unmangled func (string: String) -> String             { string clone() }
nq_trailingQuest: unmangled func (string: String) -> String           { string + "__quest" }
nq_trailingBang:  unmangled func (string: String) -> String           { string + "__bang" }
nq_error: unmangled func (this: AstBuilder, errorID: Int, message: String, index: Int) { this error(errorID, message, index) }

SyntaxError: class extends Error {
    init: super func ~tokenMessage
}

