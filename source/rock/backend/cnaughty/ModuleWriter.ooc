import structs/List
import ../../middle/[Module, Include, Import, TypeDecl, FunctionDecl,
       CoverDecl, ClassDecl, OperatorDecl]
import CoverDeclWriter, ClassDeclWriter
import Skeleton

ModuleWriter: abstract class extends Skeleton {

    write: static func (this: This, module: Module) {

        hw app("/* "). app(module fullName). app(" header file, generated with rock, the ooc compiler written in ooc */"). nl()
        fw app("/* "). app(module fullName). app(" header-forward file, generated with rock, the ooc compiler written in ooc */"). nl()
        cw app("/* "). app(module fullName). app(" source file, generated with rock, the ooc compiler written in ooc */"). nl()

        hName    := "__"+ module fullName clone() replace('/', '_') replace('\\', '_') replace('-', '_') + "__"
        hFwdName := "__"+ module fullName clone() replace('/', '_') replace('\\', '_') replace('-', '_') + "_fwd__"

        /* write the fwd-.h file */
        current = fw
        current nl(). app("#ifndef "). app(hFwdName)
        current nl(). app("#define "). app(hFwdName). nl()

        // write all includes
        for(inc: Include in module includes) {
            visitInclude(this, inc)
        }
        if(!module includes isEmpty()) current nl()

        // write all type forward declarations
        writeTypesForward(this, module, false) // non-metas first
        writeTypesForward(this, module, true)  // then metas
        if(!module types isEmpty()) current nl()

        // write imports' includes
        imports := classifyImports(this, module)
        for(imp in imports) {
            inc := imp getModule() getPath(imp isTight ? ".h" : "-fwd.h")
            current nl(). app("#include <"). app(inc). app(">")
        }

        /* write the .h file */
        current = hw
        current nl(). app("#ifndef "). app(hName)
        current nl(). app("#define "). app(hName). nl()

        current nl(). app("#include \""). app(module simpleName). app("-fwd.h\""). nl()

        /* write the .c file */
        current = cw
        // write include to the module's. h file
        current nl(). app("#include \""). app(module simpleName). app(".h\""). nl()

        // write all types, non-metas first, then metas
        for(tDecl: TypeDecl in module types) {
            if(tDecl isMeta) continue
            tDecl accept(this)
        }
        for(tDecl: TypeDecl in module types) {
            if(!tDecl isMeta) continue
            tDecl accept(this)
        }

        // write all functions
        for(fDecl: FunctionDecl in module functions) {
            fDecl accept(this)
        }

        // write all operator overloads
        for(oDecl: OperatorDecl in module operators) {
            oDecl accept(this)
        }

        // header end
        current = hw
        current nl(). nl(). app("#endif // "). app(hName)

        // forward-header end
        current = fw
        current nl(). nl(). app("#endif // "). app(hFwdName)

    }

    /** Classify imports between 'tight' and 'loose' */
    classifyImports: static func (this: This, module: Module) -> List<Import> {

        imports := module getImports() clone()

        for(selfDecl in module getTypes()) {
            for(imp in imports) {
                if(selfDecl getSuperRef() != null && selfDecl getSuperRef() getModule() == imp getModule()) {
                    // tighten imports of modules which contain classes we extend
                    imp setTight(true)
                } else if(imp getModule() getFullName() startsWith("lang/types")) {
                    // FIXME: hardcoding "types" is ugly :( :( Figure out where 'Object' and 'Class' is in a more flexible way
                    // tighten imports of core modules
                    imp setTight(true)
                } else {
                    for(member in selfDecl getVariables()) {
                        ref := member getType() getRef()
                        if(!ref instanceOf(CoverDecl)) continue
                        coverDecl := ref as CoverDecl
                        if(coverDecl getFromType() != null) continue
                        if(coverDecl getModule() != imp getModule()) continue
                        // uses compound cover, tightening!
                        imp setTight(true)
                    }
                }
            }
        }

        imports

    }

    writeTypesForward: static func (this: This, module: Module, meta: Bool) {

        for(tDecl: TypeDecl in module types) {
            if(tDecl isMeta != meta) continue
            match {
                case tDecl instanceOf(ClassDecl) =>
                    className := tDecl as ClassDecl underName()
                    ClassDeclWriter writeStructTypedef(this, className)
                case tDecl instanceOf(CoverDecl) =>
                    CoverDeclWriter writeTypedef(this, tDecl)
            }
        }

    }

    /** Write an include */
    visitInclude: static func (this: This, inc: Include) {
        chevron := (inc mode == IncludeModes PATHY)
        current nl(). app("#include "). app(chevron ? '<' : '"').
            app(inc path). app(".h").
        app(chevron ? '>' : '"')
    }

}
