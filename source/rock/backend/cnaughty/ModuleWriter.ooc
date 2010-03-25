import structs/List
import ../../middle/[Module, Include, Import, TypeDecl, FunctionDecl,
       CoverDecl, ClassDecl, OperatorDecl, InterfaceDecl, VariableDecl,
       Type]
import CoverDeclWriter, ClassDeclWriter, VersionWriter
import Skeleton

ModuleWriter: abstract class extends Skeleton {

    write: static func (this: This, module: Module) {

        hw app("/* "). app(module fullName). app(" header file, generated with rock, the ooc compiler written in ooc */"). nl()
        fw app("/* "). app(module fullName). app(" header-forward file, generated with rock, the ooc compiler written in ooc */"). nl()
        cw app("/* "). app(module fullName). app(" source file, generated with rock, the ooc compiler written in ooc */"). nl()

        hName    := "___"+ module fullName clone() replace('/', '_') replace('\\', '_') replace('-', '_') + "___"
        hFwdName := "___"+ module fullName clone() replace('/', '_') replace('\\', '_') replace('-', '_') + "_fwd___"

        /* write the fwd-.h file */
        current = fw
        current nl(). app("#ifndef "). app(hFwdName)
        current nl(). app("#define "). app(hFwdName). nl()

        // write all includes
        for(inc: Include in module includes) {
            visitInclude(this, inc)
        }
        if(!module includes isEmpty()) current nl()
        
        for(uze in module uses) {
            useDef := uze getUseDef()
			for(ynclude in useDef getIncludes()) {
				current nl(). app("#include <"). app(ynclude). app(">")
			}
		}
        
        // write all type forward declarations
        writeTypesForward(this, module, false) // non-metas first
        writeTypesForward(this, module, true)  // then metas
        if(!module types isEmpty()) current nl()

        // write imports' includes
        imports := classifyImports(this, module)
        for(imp in imports) {
            inc := imp getModule() getPath("-fwd.h")
            current nl(). app("#include <"). app(inc). app(">")
        }
        
        // write all func types typedefs
        for(funcType in module funcTypesMap) {
            current nl(). app("typedef ");
            if(funcType returnType == null) {
                current app("void")
            } else {
                current app(funcType returnType)
            }
            current app(" (*"). app(funcType toMangledString()). app(")(")
            
            isFirst := true
            for(typeArg in funcType typeArgs) {
                if(isFirst) isFirst = false
                else        current app(", ")
                current app(typeArg getType())
            }
            for(argType in funcType argTypes) {
                if(isFirst) isFirst = false
                else        current app(", ")
                current app(argType)
            }
            current app(");")
        }

        /* write the .h file */
        current = hw
        current nl(). app("#ifndef "). app(hName)
        current nl(). app("#define "). app(hName). nl()

        current nl(). app("#include \""). app(module simpleName). app("-fwd.h\""). nl()
        
		// include .h-level imports (which contains types we extend)
        for(imp in imports) {
            if(!imp isTight()) continue
            inc := imp getModule() getPath(".h")
            current nl(). app("#include <"). app(inc). app(">")
        }
        current nl()

        /* write the .c file */
        current = cw
        
        // write include to the module's. h file
        current nl(). app("#include \""). app(module simpleName). app(".h\""). nl()
        
        // now loose imports, in the .c it's safe =)
        for(imp in imports) {
            if(imp isTight()) continue
            inc := imp getModule() getPath(".h")
            current nl(). app("#include <"). app(inc). app(">")
        }
        current nl()

        // write all types, non-metas first, then metas
        for(tDecl: TypeDecl in module types) {
            if(tDecl isMeta) continue
            tDecl accept(this)
        }
        for(tDecl: TypeDecl in module types) {
            if(!tDecl isMeta) continue
            tDecl accept(this)
        }
        
        // write all global variables
        for(stmt in module body) {
            if(stmt instanceOf(VariableDecl)) {
                vd := stmt as VariableDecl
                // TODO: add 'local'
                if(vd isExtern()) continue
                current = fw
                current nl(). app("extern "). app(vd getType()). app(' '). app(vd getFullName()). app(';')
                current = cw
                current nl().                 app(vd getType()). app(' '). app(vd getFullName()). app(';')
            }
        }
        
        // write load function
        current = fw
        current nl(). app("void "). app(module getLoadFuncName()). app("();")
        current = cw
        current nl(). app("void "). app(module getLoadFuncName()). app("() {"). tab()
        current nl(). app("static "). app("bool __done__ = false;"). nl(). app("if (!__done__)"). app("{"). tab()
		current nl(). app("__done__ = true;")
        for (imp in module getAllImports()) {
			current nl(). app(imp getModule() getLoadFuncName()). app("();")
		}
        
        for (type in module types) {
            if(type instanceOf(ClassDecl)) {
                cDecl := type as ClassDecl
                finalScore: Int
                loadFunc := cDecl getFunction(ClassDecl LOAD_FUNC_NAME, null, null, finalScore&)
                if(loadFunc) {
                    if(cDecl getVersion()) VersionWriter writeStart(this, cDecl getVersion())
                    current nl(). app(loadFunc getFullName()). app("();")
                    if(cDecl getVersion()) VersionWriter writeEnd(this)
                }
            }
        }
        
        for(stmt in module body) {
            if(stmt instanceOf(VariableDecl)) {
                vd := stmt as VariableDecl
                if(vd isExtern() || vd getExpr() == null) continue
                current nl(). app(vd getFullName()). app(" = "). app(vd getExpr()). app(';')
            } else {
                writeLine(stmt)
            }
        }
        current untab(). nl(). app("}")
        current untab(). nl(). app("}"). nl()

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

        imports := module getAllImports() clone()

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
            for(interfaceDecl in tDecl getInterfaceDecls()) {
                if(!meta) {
                    CoverDeclWriter writeTypedef(this, interfaceDecl)
                }
            }
            
            if(tDecl isMeta != meta) continue
            
            match {
                case tDecl instanceOf(ClassDecl) =>
                    ClassDeclWriter writeStructTypedef(this, tDecl as ClassDecl)
                    if(tDecl instanceOf(InterfaceDecl)) {
                        CoverDeclWriter writeTypedef(this, tDecl as InterfaceDecl getFatType())
                    }
                case tDecl instanceOf(CoverDecl) =>
                    CoverDeclWriter writeTypedef(this, tDecl as CoverDecl)
            }
        }

    }

    /** Write an include */
    visitInclude: static func (this: This, inc: Include) {
        
        if(inc getVersion()) VersionWriter writeStart(this, inc getVersion())
        
        for(define in inc getDefines()) {
			current nl(). app("#ifndef "). app(define name)
			current nl(). app("#define "). app(define name)
            current nl(). app("#define "). app(define name). app("___defined")
			if(define value != null) {
                current app(' '). app(define value)
            }
			current nl(). app("#endif");
		}
        
        chevron := (inc mode == IncludeModes PATHY)
        current nl(). app("#include "). app(chevron ? '<' : '"').
            app(inc path). app(".h").
        app(chevron ? '>' : '"')
        
        for(define in inc getDefines()) {
            current nl(). app("#ifdef "). app(define name). app("___defined")
            current nl(). app("#undef "). app(define name)
            current nl(). app("#undef "). app(define name). app("___defined")
            current nl(). app("#endif")
        }
        
        if(inc getVersion()) VersionWriter writeEnd(this)
        
    }

}
