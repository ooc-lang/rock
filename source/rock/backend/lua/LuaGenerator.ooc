import io/[File, FileWriter, BufferWriter]
import structs/[Bag, HashBag, MultiMap, List, ArrayList, HashMap]
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

import ../../backend/cnaughty/[FunctionDeclWriter, Skeleton, AwesomeWriter, CGenerator,
        ClassDeclWriter, CoverDeclWriter, EnumDeclWriter]

LuaGenerator: class extends CGenerator {

    outFile: File
    funcs, bind, bindEnums, types, imports, classes: Buffer
    funcsWriter, bindWriter, bindEnumsWriter, typesWriter, importsWriter, classesWriter: AwesomeWriter

    init: func (=params, =module) {
        outFile = File new(params outPath getPath(), module getPath(".lua"))
        outFile parent mkdirs()

        types = Buffer new()
        typesWriter = AwesomeWriter new(this, BufferWriter new(types))
        typesWriter app("local _typesdeclared = false"). nl().
                    app("function _module.declare_types()"). tab(). nl().
                    app("if _typesdeclared then return end"). nl().
                    app("_typesdeclared = true"). nl().
                    app("howling.import_types(_tight_imports)"). nl().
                    app("howling.import_types(_loose_imports)"). nl(). nl().
                    app("ffi.cdef[["). nl()

        funcs = Buffer new()
        funcsWriter = AwesomeWriter new(this, BufferWriter new(funcs))
        funcsWriter app("local _funcsdeclared = false"). nl().
                    app("function _module.declare_and_bind_funcs()"). tab(). nl().
                    app("if _funcsdeclared then return end"). nl().
                    app("_funcsdeclared = true"). nl().
                    app("howling.import_funcs(_tight_imports)"). nl().
                    app("howling.import_funcs(_loose_imports)"). nl(). nl().
                    app("ffi.cdef[["). nl()

        classes = Buffer new()
        classesWriter = AwesomeWriter new(this, BufferWriter new(classes))
        classesWriter app("local _classesdeclared = false"). nl().
                      app("function _module.declare_classes()"). tab(). nl().
                      app("if _classesdeclared then return end"). nl().
                      app("_classesdeclared = true"). nl().
                      app("howling.import_classes(_tight_imports)"). nl(). nl().
                      app("ffi.cdef[["). nl()

        bind = Buffer new()
        bindWriter = AwesomeWriter new(this, BufferWriter new(bind))
        bindWriter tab(). nl()

        bindEnums = Buffer new()
        bindEnumsWriter = AwesomeWriter new(this, BufferWriter new(bindEnums))
        bindEnumsWriter tab(). nl()

        imports = Buffer new()
        importsWriter = AwesomeWriter new(this, BufferWriter new(imports))

        current = funcsWriter
    }

    write: func {
        visitModule(module)
    }

    /** generate now, actually. */
    close: func {
        writer := FileWriter new(outFile)
        // close the types declaration
        typesWriter app("]]"). untab(). nl().
                    app("end"). nl(). nl()
        // add the binds to the funcs
        funcsWriter app("]]"). nl().
                    app(bind toString()). untab(). nl().
                    app("end"). nl(). nl()
        // close classes
        classesWriter app("]]"). untab(). nl().
                      app(bindEnums toString()). untab(). nl().
                      app("end"). nl(). nl()

        // write the funcs part
        writer write("local howling = require(\"howling\")\n").
               write("local _module = howling.Module:new(\"#{module getFullName()}\")\n").
               write("local ffi = require(\"ffi\")\n\n").
               write(imports toString()).
               write(types toString()).
               write(funcs toString()).
               write(classes toString())
        // and finally, return the new module.
        writer write("return _module\n")
        writer close()
    }

    shouldBindFunction: func (node: FunctionDecl) -> Bool {
        // Skip versioned functions
        if (node getVersion()) {
            return false
        }

        // We could probably load extern functions, but let's not do that. (TODO?)
        if (node isExtern()) {
            return false
        }

        // Skip main
        if (node isEntryPoint()) {
            return false
        }

        // Ignore closures
        if (node fromClosure) {
            return false
        }

        // Ignore __...__ functions, but keep getters and setters
        if (node name startsWith?("__") &&
            node name endsWith?("__") &&
                !(node name startsWith?("__get") || node name startsWith?("__set"))) {
            return false
        }

        return true
    }

    /** Replace all object arguments with void* arguments. */
    prepareArgument: func (voidPointer: Type, arg: VariableDecl) {
        if(!arg instanceOf?(VarArg)) {
            if(arg getType() getRef() instanceOf?(ClassDecl)) {
                arg setType(voidPointer)
            }
        }
    }

    /** return a new function decl whose object parameter types are all void*
     * This is because LuaJIT FFI is very strict about pointer types.
     */
    prepareFunctionDecl: func (orig: FunctionDecl) -> FunctionDecl {
        voidPointer := PointerType new(voidType, orig token)
        node := orig clone()
        // TODO: Ideally, this would also modify the thisPointer. But cloning
        // TypeDecls isn't supported, and modifying the AST feels bad.
        node args each(|arg|
            prepareArgument(voidPointer, arg)
        )
        node
    }

    /** Write the function prototype to the funcs buffer. */
    visitFunctionDecl: func (node: FunctionDecl) {
        if (!shouldBindFunction(node)) return
        node = prepareFunctionDecl(node)
        current = funcsWriter
        // funcs: write the function prototype
        FunctionDeclWriter writeFuncPrototype(this, node)
        current app(';') .nl()
        // bind: bind a function if it isn't a member.
        // if it is a member, `visitClassDecl` does the binding.
        if (!node isMember()) {
            current = bindWriter
            bindWriter app("_module:func(\"")
            FunctionDeclWriter writeSuffixedName(this, node)
            bindWriter app("\")") .nl()
        }
    }

    visitClassDecl: func (node: ClassDecl) {
        // Skip versioned classes
        if (node getVersion())
            return
        if (node isMeta)
            return
        // write the struct typedefs to `types` (makes them opaque, but that
        // should be enough for now)
        current = typesWriter
        ClassDeclWriter writeStructTypedef(this, node)
        typesWriter nl()
        generateClasslike(node)
        // write the struct contents to `classes`
        current = classesWriter
        rename := "_#{node underName()}__hidden"
        // Write the struct containing the actual fields.
        ClassDeclWriter writeObjectStruct(this, node, rename)
        // Write a struct only containing a reference to that struct
        current app("struct _#{node underName()} "). openBlock(). nl().
                app("struct #{rename} _values;"). nl(). closeBlock(). app(';')
        classesWriter nl()
    }

    /** Classes and covers. */
    generateClasslike: func (node: TypeDecl) {
        // Collect all functions to bind them.
        functions := ArrayList<String> new()
        for (function in node meta functions) {
            // Ignore functions we should not bind
            if (!shouldBindFunction(function)) {
                continue
            }

            // Write the funcs code
            function accept(this)
            name := function name
            if (function getSuffix())
                name = "%s_%s" format(name, function getSuffix())
            functions add(name)
        }

        bindWriter app("local _class = _module:class(\"#{node name}\", {"). tab(). nl()
        // Write the bind code.
        {
            bindWriter app("functions = {"). tab(). nl()
            first := true
            for (name in functions) {
                if (!first) bindWriter app(','). nl()
                else first = false
                bindWriter app('"'). app(name). app('"')
            }
            bindWriter untab(). nl(). app("},"). nl()
        }
        // collect attributes and properties
        {
            properties := ArrayList<String> new()
            members := ArrayList<String> new()
            iter := node variables iterator()
            while(iter hasNext?()) {
                node := iter next()
                if(node instanceOf?(PropertyDecl)) {
                    // found a PropertyDecl howling should know about
                    properties add(node name)
                } else {
                    // ... or an attribute
                    members add(node name)
                }
            }
            {
                bindWriter app("properties = {"). tab(). nl()
                first := true
                for(prop in properties) {
                    if(!first) bindWriter app(','). nl()
                    else first = false
                    bindWriter app('"'). app(prop). app('"')
                }
                bindWriter untab(). nl(). app("},"). nl()
            }
            {
                bindWriter app("members = {"). tab(). nl()
                first := true
                for(member in members) {
                    if(!first) bindWriter app(','). nl()
                    else first = false
                    bindWriter app('"'). app(member). app('"')
                }
                bindWriter untab(). nl(). app("}"). nl()
            }
        }
        bindWriter untab(). nl(). app("})"). nl()
    }

    /** Enums. */
    generateEnumlike: func (node: EnumDecl) {
        bindEnumsWriter app("local _enum = _module:enum(\"#{node name}\", {"). tab(). nl()
        // Write the bind code.
        {
            bindEnumsWriter app("values = {"). tab(). nl()
            first := true
            for (variable in node meta variables) {
                if(!first) bindEnumsWriter app(','). nl()
                else first = false
                bindEnumsWriter app('"'). app(variable name). app('"')
            }
            bindEnumsWriter untab(). nl(). app("}")
        }
        bindEnumsWriter untab(). nl(). app("})"). nl()
    }

    visitCoverDecl: func (node: CoverDecl) {
        // Skip versioned classes
        if (node getVersion()) {
            return
        }

        // Skip extern covers
        if (node isExtern()) {
            return
        }

        // Skip 'closure covers'
        if (node fromClosure) {
            return
        }

        // Write the typedef to `types`
        current = typesWriter

        if (node isProto) {
            fullName := node getFullName()
            typesWriter app("typedef struct _#{fullName} #{fullName};"). nl()

            old := current
            current = classesWriter
            CoverDeclWriter writeGuts(this, node)
            current = old
            return
        }

        // if we are binding an extern type, we need an opaque type definition as well.
        // but let's assume that SDK definitions don't need that. (TODO)
        if (node fromType) {
            fromName := node fromType getName()
            // we don't need an opaque type if we're covering structs or unions
            if (!(fromName startsWith?("struct ") || fromName startsWith?("union") ||
                module getUseDef() identifier == "sdk")) {
                typesWriter app("typedef struct ___#{fromName} #{fromName};"). nl()
            }
        } else {
            // FIXME blacklisting stuff here is a terrible terrible workaround
            if (node name != "_StackFrame") {
                old := current
                current = classesWriter
                CoverDeclWriter writeGuts(this, node)
                current = old
            }
        }
        CoverDeclWriter writeTypedef(this, node)

        typesWriter nl()
    }


    visitVariableDecl: func (node: VariableDecl) {
        super(node)
    }

    visitEnumDecl: func (node: EnumDecl) {
        // Enums are "wrapped" by typedef'ing them to int, for now. TODO.
        if (!node isExtern()) {
            typesWriter app("typedef int "). app(node underName()). app(';'). nl()
        }
        generateEnumlike(node)
    }

    visitOperatorDecl: func (node: OperatorDecl) {

    }

    visitInterfaceDecl: func (node: InterfaceDecl) {
        // write the meta class decl typedef
        current = typesWriter
        ClassDeclWriter writeStructTypedef(this, node getMeta())

        // then write the fat type
        current = classesWriter
        node fatType accept(this)
    }

    visitInterfaceImpl: func (node: InterfaceImpl) {

    }

    visitModule: func (node: Module) {
        // Import the imports!
        importsWriter app("local _tight_imports, _loose_imports = {}, {}"). nl().
                      app("_module._loose_imports = _loose_imports")
        for (imp in module getGlobalImports()) {
            imported := imp getModule()
            path := "#{imported getUseDef() identifier}:#{imported path}"
            table := imp isTight ? "_tight_imports" : "_loose_imports"
            importsWriter nl(). app("table.insert(#{table}, \"#{path}\")")
        }

        importsWriter nl(). nl()

        for (function in node functions) {
            function accept(this)
        }

        for (type in node types) {
            type accept(this)
        }

        for (op in node operators) {
            visitOperatorDecl(op)
        }

        // write globals in 'classes' block
        current = classesWriter
        for (child in node body) {
            match child {
                case vDecl: VariableDecl =>
                    if (!vDecl isGenerated) {
                        vDecl getType() accept(this)
                        current app(" "). app(vDecl getFullName()). app(";"). nl()
                    }
            }
        }
    }
}
