import ../../middle/[Module, Include, Import, TypeDecl, FunctionDecl, CoverDecl, ClassDecl]
import CoverDeclWriter, ClassDeclWriter
import Skeleton

ModuleWriter: abstract class extends Skeleton {
    
    write: static func (this: This, module: Module) {

        hw app("/* "). app(module fullName). app(" header file, generated with rock, the ooc compiler written in ooc */"). nl()
        fw app("/* "). app(module fullName). app(" header-forward file, generated with rock, the ooc compiler written in ooc */"). nl()
        cw app("/* "). app(module fullName). app(" source file, generated with rock, the ooc compiler written in ooc */"). nl()

        hName := "__"+ module fullName clone() replace('/', '_') replace('-', '_') + "__"
        
        /* write the fwd-.h file */
        current = fw
        
        // write all includes
        for(inc: Include in module includes) {
            visitInclude(this, inc)
        }
        if(!module includes isEmpty()) current nl()
        
        // write all type forward declarations
        for(tDecl: TypeDecl in module types) {
            if(tDecl isMeta) continue
            match (tDecl class) {
                case ClassDecl =>
                    className := tDecl as ClassDecl underName()
                    ClassDeclWriter writeStructTypedef(this, className)
                case CoverDecl =>
                    CoverDeclWriter writeTypedef(this, tDecl)
            }
        }
        for(tDecl: TypeDecl in module types) {
            if(!tDecl isMeta) continue
            match (tDecl class) {
                case ClassDecl =>
                    className := tDecl as ClassDecl underName()
                    ClassDeclWriter writeStructTypedef(this, className)
                case CoverDecl =>
                    CoverDeclWriter writeTypedef(this, tDecl)
            }
        }
        if(!module types isEmpty()) current nl()
        
        // write imports' includes
        for(imp: Import in module imports) {
			inc := imp getModule() getPath(".h")
			current nl(). app("#include <"). app(inc). app(">")
		}
        if(!module imports isEmpty()) current nl()

        /* write the .h file */
        current = hw
        current nl(). app("#ifndef "). app(hName)
        current nl(). app("#define "). app(hName). nl()
        
        current nl(). app("#include \""). app(module simpleName). app("-fwd.h\""). nl()
        
        /* write the .c file */
        current = cw
        // write include to the module's. h file
        current nl(). app("#include \""). app(module simpleName). app(".h\""). nl()
        
        // write all types
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
            visitFunctionDecl(fDecl)
        }
        
        // header end
        current = hw
        current nl(). nl(). app("#endif // "). app(hName)
        
    }
    
    /** Write an include */
    visitInclude: static func (this: This, inc: Include) {
        chevron := (inc mode == IncludeModes PATHY)
        current nl(). app("#include "). app(chevron ? '<' : '"').
            app(inc path). app(".h"). 
        app(chevron ? '>' : '"')
    }

}
