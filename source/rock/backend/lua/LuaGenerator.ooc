import io/[File, FileWriter, BufferWriter]
import structs/[Bag, HashBag, MultiMap, List, ArrayList]
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
        ClassDeclWriter]

LuaGenerator: class extends CGenerator {

    outFile: File
    cdecl, bind: Buffer
    cdeclWriter, bindWriter: AwesomeWriter

    init: func (=params, =module) {
        outFile = File new(params outPath getPath(), module getPath(".lua"))
        outFile parent mkdirs()

        cdecl = Buffer new()
        cdeclWriter = AwesomeWriter new(this, BufferWriter new(cdecl))

        bind = Buffer new()
        bindWriter = AwesomeWriter new(this, BufferWriter new(bind))

        current = cdeclWriter
    }

    write: func {
        visitModule(module)
    }

    /** generate now, actually. */
    close: func {
        writer := FileWriter new(outFile)
        // write the cdecl part
        writer write("local howling = require(\"howling\")\n").
               write("local ffi = require(\"ffi\")\n\n").
               write("ffi.cdef[[\n")
        writer write(cdecl toString())
        writer write("]]\n\n")
        // write the bind part
        writer write(bind toString())
        // and finally, return the new module.
        writer write("\nreturn _module\n")
        writer close()
    }

    /** Write the function prototype to the cdecl buffer. */
    visitFunctionDecl: func (node: FunctionDecl) {
        current = cdeclWriter
        // cdecl: write the function prototype
        FunctionDeclWriter writeFuncPrototype(this, node)
        current app(';') .nl()
        // bind: bind a function if it isn't a member.
        // if it is a member, `visitClassDecl` does the binding.
        if(!node isMember()) {
            current = bindWriter
            bindWriter app("_module:func(\"")
            FunctionDeclWriter writeSuffixedName(this, node)
            bindWriter app("\")") .nl()
        }
    }

    visitClassDecl: func (node: ClassDecl) {
        if(node isMeta)
            return
        // write the struct typedefs to cdecl (makes them opaque, but that
        // should be enough for now)
        current = cdeclWriter
        ClassDeclWriter writeStructTypedef(this, node)
        cdeclWriter nl()
        // Collect all functions to bind them.
        functions := ArrayList<String> new()
        for(function in node meta functions) {
            // Write the cdecl code
            function accept(this)
            name := function name
            if(function getSuffix())
                name = "%s_%s" format(name, function getSuffix())
            functions add(name)
        }
        // Write the bind code.
        bindWriter app("local _class = _module:class(\"#{node name}\", {"). tab(). nl().
                   app("functions = {"). tab(). nl()
        first := true
        for(name in functions) {
            if(!first) bindWriter app(','). nl()
            else first = false
            bindWriter app('"'). app(name). app('"')
        }
        bindWriter untab(). nl(). app("}"). untab(). nl(). app("})"). nl()
    }

    /** Don't write a cover declaration */
    visitCoverDecl: func (cDecl: CoverDecl) {
    }


    visitVariableDecl: func (node: VariableDecl) {
        /* Only generate code for argument variable decls, not global variables */
        // TODO: What is the best way?
        if(!node isStatic())
            super(node)
    }

    visitEnumDecl: func (node: EnumDecl) {

    }

    visitOperatorDecl: func (node: OperatorDecl) {

    }

    visitInterfaceDecl: func (node: InterfaceDecl) {

    }

    visitInterfaceImpl: func (node: InterfaceImpl) {

    }

    visitModule:             func (node: Module) {
        // bind code: Add module
        name := node getFullName()
        bindWriter app("local _module = howling.Module:new(\"#{name}\")") .nl()
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
