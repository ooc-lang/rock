import io/[File, FileWriter]
import structs/[Bag, HashBag, MultiMap, List]
import text/json/Generator

import ../../frontend/[BuildParams, Token]

import ../../middle/[Visitor]

import ../../middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, CharLiteral, StringLiteral, RangeLiteral,
    VariableDecl, If, Else, While, Foreach, Conditional, ControlStatement,
    VariableAccess, Include, Import, Use, TypeDecl, ClassDecl, CoverDecl,
    Node, Parenthesis, Return, Cast, Comparison, Ternary, BoolLiteral,
    Argument, Statement, AddressOf, Dereference, FuncType, BaseType, PropertyDecl,
    EnumDecl, OperatorDecl, InterfaceDecl, InterfaceImpl, Version, TypeList]

JSONGenerator: class extends Visitor {

    VERSION := static "2.0.0"

    params: BuildParams
    outFile: File
    module: Module
    root: HashBag
    objects: MultiMap<String, HashBag>

    init: func (=params, =module) {
        outFile = File new(params outPath getPath(), module getPath(".json"))
        outFile parent mkdirs()
        root = HashBag new()
        objects = MultiMap<String, HashBag> new()

        /* build the structure! */
        root put("version", VERSION)

        root put("path", module path)

        globalImports := Bag new()
        for(imp in module getGlobalImports())
            globalImports add(imp getModule() path)
        root put("globalImports", globalImports)

        namespacedImports := HashBag new()
        for(ns in module namespaces) {
            modules := Bag new()
            for(imp in ns getImports()) {
                modules add(imp getModule() path)
            }
            namespacedImports put(ns getName(), modules)
        }
        root put("namespacedImports", namespacedImports)

        uses := Bag new()
        for(uze in module getUses()) {
            uses add(uze identifier)
        }
        root put("uses", uses)
    }

    write: func {
        visitModule(module)
    }

    addObject: func (tag: String, obj: HashBag) {
        objects put(tag, obj)
    }

    putToken: func (obj: HashBag, token: Token) {
        bag := Bag new()
        bag add(token start as UInt) .add(token length as UInt)
        obj put("token", bag)
    }

    resolveType: func (type: Type, full := false) -> String {
        if(type instanceOf?(FuncType)) {
            return generateFuncTag(type as FuncType, full)
        } else if(type instanceOf?(ArrayType)) {
            return "array(%s)" format(resolveType(type as ArrayType inner, full))
        } else if(type instanceOf?(PointerType)) {
            return "pointer(%s)" format(resolveType(type as PointerType inner, full))
        } else if(type instanceOf?(ReferenceType)) {
            return "reference(%s)" format(resolveType(type as ReferenceType inner, full))
        } else if(type instanceOf?(TypeList)) {
            buffer := Buffer new()
            buffer append("multi(")
            isFirst := true
            for(subtype in type as TypeList types) {
                if(isFirst) isFirst = false
                else        buffer append(",")
                buffer append(resolveType(subtype, full))
            }
            buffer append(')')
            return buffer toString()
        } else if(type instanceOf?(BaseType)) {
            /* base type */
            if (full) {
                ref := type getRef()
                match ref {
                    case td: TypeDecl =>
                        td getFullName()
                    case =>
                        "any"
                }
            } else {
                return type as BaseType name /* TODO? */
            }
        } else {
            "any"
        }
    }

    /** generate now, actually. */
    close: func {
        // add the entities to root (first construct it, yeah!)
        bag := Bag new()
        for(key: String in objects getKeys()) {
            subbag := Bag new()
            subbag add(key)
            val := objects getAll(key) as Object
            if(val instanceOf?(List)) {
                for(obj: HashBag in (val as List<HashBag>)) {
                    subbag add(obj)
                }
            } else {
                subbag add(val as HashBag)
            }
            bag add(subbag)
        }
        root put("entities", bag)
        // don't beautify, don't indent.
        writer := FileWriter new(outFile)
        generate(writer, root)
        writer close()
    }

    translateVersionSpec: func (spec: VersionSpec) -> String {
        match (spec class) {
            case VersionName => {
                return spec as VersionName name
            }
            case VersionNegation => {
                return "not(%s)" format(translateVersionSpec(spec as VersionNegation inner))
            }
            case VersionAnd => {
                mySpec := spec as VersionAnd
                return "and(%s,%s)" format(
                        translateVersionSpec(mySpec specLeft),
                        translateVersionSpec(mySpec specRight))
            }
            case VersionOr => {
                mySpec := spec as VersionOr
                return "or(%s,%s)" format(
                        translateVersionSpec(mySpec specLeft),
                        translateVersionSpec(mySpec specRight))
            }
            case => {
                Exception new("Unknown version spec class: %s" format(spec class name)) throw()
            }
        }
        null
    }

    putVersion: func (verzion: VersionSpec, obj: HashBag) {
        if(verzion) {
            obj put("version", translateVersionSpec(verzion))
        } else {
            obj put("version", null)
        }
    }

    visitClassDecl: func (node: ClassDecl) {
        if(node isMeta)
            return
        obj := HashBag new()
        putToken(obj, node token)
        /* `name` */
        obj put("name", node name as String)
        /* `version` */
        putVersion(node verzion, obj)
        /* `type` */
        obj put("type", "class")
        /* `abstract` */
        obj put("abstract", node isAbstract)
        /* `final` */
        obj put("final", node isFinal)
         /* `nameFqn` */
        obj put("nameFqn", node underName())
        /* `tag` */
        obj put("tag", node name as String)
        /* `doc` */
        obj put("doc", node doc)
        /* `extends` */
        if(node getSuperRef() != null) {
            obj put("extendsFqn", node getSuperRef() getFullName())
            obj put("extends", node getSuperRef() name as String)
        } else {
            obj put("extendsFqn", null)
            obj put("extends", null)
        }
        /* generic types */
        genericTypes := Bag new()
        for(typeArg in node typeArgs) {
            genericTypes add(typeArg name as String)
        }
        obj put("genericTypes", genericTypes)
        /* `members` */
        members := Bag new()
        /* methods */
        for(function in node meta functions) {
            member := Bag new()
            member add(function name) .add(buildFunctionDecl(function, "method"))
            members add(member)
        }
        /* variables */
        for(variable in node variables) {
            member := Bag new()
            member add(variable name) .add(buildVariableDecl(variable, "field"))
            members add(member)
        }
        /* static variables */
        for(variable in node meta variables) {
            member := Bag new()
            member add(variable name) .add(buildVariableDecl(variable, "field"))
            members add(member)
        }
        obj put("members", members)
        addObject(node name, obj)
        for(idecl in node getInterfaceDecls())
            visitInterfaceImpl(idecl)
    }

    visitCoverDecl: func (node: CoverDecl) {
        if (node isGenerated) { return }
        obj := HashBag new()
        putToken(obj, node token)
        /* `name` */
        obj put("name", node name as String)
        /* `type` */
        obj put("type", "cover")
        /* `doc` */
        obj put("doc", node doc)
        /* `version` */
        putVersion(node verzion, obj)
        /* `tag` */
        obj put("tag", node name as String)
        /* `nameFqn` */
        obj put("nameFqn", node underName())
        /* `extends` */
        if(node getSuperRef() != null) {
            obj put("extendsFqn", node getSuperRef() getFullName())
            obj put("extends", node getSuperRef() name as String)
        } else {
            obj put("extendsFqn", null)
            obj put("extends", null)
        }
        /* `from` */
        if(node fromType != null) {
            obj put("from", node fromType toString())
            fromRef := node fromType getRef()
            match fromRef {
                case td: TypeDecl =>
                    obj put("fromFqn", td getFullName())
                case =>
                    obj put("fromFqn", "any")
            }
        } else {
            obj put("from", null)
            obj put("fromFqn", null)
        }
        /* `members` */
        members := Bag new()
        for(function in node meta functions) {
            member := Bag new()
            member add(function name) .add(buildFunctionDecl(function, "method"))
            members add(member)
        }
        for(variable: VariableDecl in node variables) {
            member := Bag new()
            member add(variable name) .add(buildVariableDecl(variable, "field"))
            members add(member)
        }
        obj put("members", members)
        addObject(node name, obj)
        for(idecl in node getInterfaceDecls())
            visitInterfaceImpl(idecl)
    }

    visitFunctionDecl: func (node: FunctionDecl) {
        if (node isGenerated) { return }
        /* add to the objects. */
        obj := buildFunctionDecl(node, "function")
        addObject(node name, obj)
    }

    buildFunctionDecl: func ~typed (node: FunctionDecl, type: String) -> HashBag {
        obj := HashBag new()
        putToken(obj, node token)
        name : String = null
        if(node suffix)
            name = "%s~%s" format(node name, node suffix)
        else
            name = node name
        /* `name` */
        obj put("name", name)
        /* `version` */
        putVersion(node verzion, obj)
        /* `isThisRef` */
        obj put("isThisRef", node isThisRef)
        /* `doc` */
        obj put("doc", node doc)
        /* `tag` */
        if(type == "method") {
            obj put("tag", "method(%s, %s)" format(node owner name, name))
        } else {
            obj put("tag", name)
        }
        /* `type` */
        obj put("type", type)
        /* `extern` */
        if(node isExtern()) {
            if(!node isExternWithName())
                obj put("extern", true)
            else
                obj put("extern", node externName)
        } else {
            obj put("extern", false)
        }
        /* `unmangled` */
        if(node isUnmangled()) {
            if(!node isUnmangledWithName())
                obj put("unmangled", true)
            else
                obj put("unmangled", node getUnmangledName())
        }
        else {
            obj put("unmangled", false)
        }
        /* `nameFqn` */
        obj put("nameFqn", node getFullName())
        /* `modifiers` */
        modifiers := Bag new()
        if(node isAbstract())
            modifiers add("abstract")
        if(node isStatic())
            modifiers add("static")
        if(node isInline())
            modifiers add("inline")
        if(node isFinal())
            modifiers add("final")
        obj put("modifiers", modifiers)
        /* generic types */
        genericTypes := Bag new()
        for(typeArg in node typeArgs) {
            genericTypes add(typeArg name as String)
        }
        obj put("genericTypes", genericTypes)
        /* return type */
        if(node returnType != voidType) {
            obj put("returnTypeFqn", resolveType(node getReturnType(), true))
            obj put("returnType", resolveType(node getReturnType()))
        } else {
            obj put("returnType", null)
        }
        /* arguments */
        args := Bag new()
        for(arg in node args) {
            l := Bag new()
            if(arg instanceOf?(VarArg)) {
                if(arg name == null) {
                    // C varargs
                    l add("...") .add("...")
                } else {
                    // ooc varargs
                    l add(arg name) .add("...")
                }
            } else {
                l add(arg name) \
                 .add(resolveType(arg type)) /* this handles generic types well. */
            }
            if(arg isConst) {
                m := Bag new()
                m add("const")
                l add(m)
            } else {
                l add(null)
            }
            l add(resolveType(arg type, true))
            args add(l)
        }
        obj put("arguments", args)
        obj
    }

    visitVariableDecl: func (node: VariableDecl) {
        if (node isGenerated) { return }
        /* add to the objects */
        obj := buildVariableDecl(node, "globalVariable")
        addObject(node name, obj)
    }

    buildVariableDecl: func (node: VariableDecl, type: String) -> HashBag {
        obj := HashBag new()
        putToken(obj, node token)
        /* `name` */
        obj put("name", node name)
        /* `doc` */
        obj put("doc", node doc)
        /* `version` */
        obj put("version", null) // TODO: change when we have version support
        /* `extern` */
        if(node isExtern()) {
            if(node externName empty?())
                obj put("extern", true)
            else
                obj put("extern", node externName)
        } else {
            obj put("extern", false)
        }
        /* `nameFqn` */
        obj put("nameFqn", node getFullName())
         /* `unmangled` */
        if(node isUnmangled()) {
            if(!node isUnmangledWithName())
                obj put("unmangled", true)
            else
                obj put("unmangled", node getUnmangledName())
        }
        else {
            obj put("unmangled", false)
        }
        /* `type` */
        obj put("type", type)
        /* `tag` */
        if(type == "field") {
            obj put("tag", "field(%s, %s)" format(node owner name, node name))
        } else {
            obj put("tag", node name)
        }
        /* `modifiers` */
        modifiers := Bag new()
        if(node isStatic)
            modifiers add("static")
        if(node isConst)
            modifiers add("const")
        obj put("modifiers", modifiers)
        /* `value` */
        if(node expr != null) {
            obj put("value", node expr toString())
        } else {
            obj put("value", null)
        }
        /* property data? */
        if(node instanceOf?(PropertyDecl)) {
            data := HashBag new()
            pnode := node as PropertyDecl
            data put("hasGetter", pnode getter != null)
            data put("hasSetter", pnode setter != null)
            if(pnode getter != null) {
                data put("fullGetterName", pnode getter getFullName())
            } else {
                data put("fullGetterName", null)
            }
            if(pnode setter != null) {
                data put("fullSetterName", pnode setter getFullName())
            } else {
                data put("fullSetterName", null)
            }
            obj put("propertyData", data)
        } else {
            obj put("propertyData", null)
        }
        /* `varType` */
        obj put("varType", resolveType(node type))
        obj put("varTypeFqn", resolveType(node type, true))
        obj
    }

    visitEnumDecl: func (node: EnumDecl) {
        obj := HashBag new()
        putToken(obj, node token)
        /* `name` */
        obj put("name", node name)
        /* `type` */
        obj put("type", "enum")
        /* `version` */
        putVersion(node verzion, obj)
        /* `tag` */
        obj put("tag", node name)
        /* `extern` */
        if(node isExtern()) {
            if(node externName empty?())
                obj put("extern", true)
            else
                obj put("extern", node externName)
        } else {
            obj put("extern", false)
        }
        /* `doc` */
        obj put("doc", node doc)
        /* `incrementOper` */
        obj put("incrementOper", node incrementOper toString())
        /* `incrementStep` */
        obj put("incrementStep", node incrementStep)
        /* `elements` */
        elements := Bag new()
        obj put("elements", elements)
        for(var in node getMeta() getVariables()) {
            if(!var instanceOf?(EnumElement))
                continue
            elem := var as EnumElement
            elemInfo := HashBag new()
            elemInfo put("name", elem name) \
                    .put("tag", "enumElement(%s, %s)" format(node name, elem name)) \
                    .put("type", "enumElement") \
                    .put("value", elem value ? elem value toString() : null) \
                    .put("doc", "")
            if(elem isExtern()) {
                // see `EnumDecl addElement`, elements always have an extern name if they are extern
                elemInfo put("extern", elem getExternName())
            } else {
                elemInfo put("extern", null)
            }
            /* add it, finally */
            elemBag := Bag new()
            elemBag add(elem name)
            elemBag add(elemInfo)
            elements add(elemBag)
        }
        addObject(node name, obj)
    }

    generateFuncTag: func ~funcType (node: FuncType, full := false) -> String {
        buf := Buffer new()
        buf append("Func(")
        first := true
        if(node typeArgs != null && !node typeArgs empty?()) {
            first = false
            first_ := true
            buf append("generics(")
            for(typeArg in node typeArgs) {
                if(!first_)
                    buf append(',')
                else
                    first_ = false
                buf append(typeArg name)
            }
            buf append(')')
        }
        if(node argTypes != null && !node argTypes empty?()) {
            if(!first)
                buf append(',')
            else
                first = false
            // TODO: C/ooc varargs?
            buf append("arguments(")
            first_ := true
            for(arg in node argTypes) {
                if(!first_)
                    buf append(',')
                else
                    first_ = false
                buf append(resolveType(arg, full))
            }
            buf append(')')
        }
        if(node returnType != null) {
            if(!first)
                buf append(',')
            else
                first = false
            buf append("return(%s)" format(resolveType(node returnType, full)))
        }
        buf append(')')
        buf toString()
    }

    generateFuncTag: func (node: FunctionDecl, start: String) -> String {
        buf := Buffer new()
        buf append(start)
        first := true
        if(!node typeArgs empty?()) {
            first = false
            first_ := true
            buf append("generics(")
            for(typeArg in node typeArgs) {
                if(!first_)
                    buf append(',')
                else
                    first_ = false
                buf append(typeArg name)
            }
            buf append(')')
        }
        if(!node args empty?()) {
            if(!first)
                buf append(',')
            else
                first = false
            buf append("arguments(")
            first_ := true
            for(arg in node args) {
                if(!first_)
                    buf append(',')
                else
                    first_ = false
                buf append(resolveType(arg type))
            }
            buf append(')')
        }
        if(node returnType != voidType) {
            if(!first)
                buf append(',')
            else
                first = false
            buf append("return(%s)" format(resolveType(node getReturnType())))
        }
        buf append(')')
        buf toString()
    }

    visitOperatorDecl: func (node: OperatorDecl) {
        obj := HashBag new()
        putToken(obj, node token)
        name := node getName()
        tag := generateFuncTag(node getFunctionDecl(), "operator(%s," format(name))
        obj put("symbol", node symbol) \
           .put("name", name) \
           .put("tag", tag) \
           .put("doc", "") \
           .put("type", "operator") \
           .put("function", buildFunctionDecl(node getFunctionDecl(), "function"))
        /* `version` */
        obj put("version", null) // TODO?
        addObject(tag, obj)
    }

    visitInterfaceDecl: func (node: InterfaceDecl) {
        obj := HashBag new()
        putToken(obj, node token)
        obj put("tag", node name) .put("name", node name) .put("doc", node doc) .put("type", "interface")
        /* `version` */
        putVersion(node verzion, obj)
        /* methods */
        members := Bag new()
        for(function in node meta functions) {
            member := Bag new()
            member add(function name) .add(buildFunctionDecl(function, "method"))
            members add(member)
        }
        obj put("members", members)
        addObject(node name, obj)
    }

    visitInterfaceImpl: func (node: InterfaceImpl) {
        obj := HashBag new()
        putToken(obj, node token)
        name := node getSuperType() getName()
        target := node impl getName()
        tag := "interfaceImpl(%s, %s)" format(name, target)
        /* `version` */
        putVersion(node verzion, obj)
        obj put("tag", tag) \
           .put("type", "interfaceImpl") \
           .put("doc", "") \
           .put("interface", name) \
           .put("for", target)
        addObject(tag, obj)
    }

    visitType: func (node: Type) {}

    visitModule:             func (node: Module) {
        for(function in node functions)
            function accept(this)
        for(type in node types)
            type accept(this)
        for(op in node operators) {
            visitOperatorDecl(op)
        }
        for(child in node body)
            if(child instanceOf?(VariableDecl))
                child accept(this)
    }
}
