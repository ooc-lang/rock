import ../middle/[Module, Include, TypeDecl, FunctionDecl, CoverDecl]
import CoverDeclWriter
import Skeleton

ModuleWriter: abstract class extends Skeleton {
    
    write: static func (this: This, module: Module) {

        hw app("/* "). app(module fullName). app(" header file, generated with rock, the ooc compiler written in ooc */"). nl()
        fw app("/* "). app(module fullName). app(" header-forward file, generated with rock, the ooc compiler written in ooc */"). nl()
        cw app("/* "). app(module fullName). app(" source file, generated with rock, the ooc compiler written in ooc */"). nl()

        hName := "__"+ module fullName clone() replace('/', '_') replace('-', '_') + "__"
        
        // forward header
        current = fw
        
        // write all type forward declarations
        for(tDecl: TypeDecl in module types) {
            printf("Writing forward type %s\n", tDecl name)
            match (tDecl class) {
                case CoverDecl =>
                    CoverDeclWriter writeTypedef(this, tDecl)
            }
        }

        // header
        current = hw
        current nl(). app("#ifndef "). app(hName)
        current nl(). app("#define "). app(hName). nl()

        // write all includes
        for(inc: Include in module includes) {
            visitInclude(this, inc)
        }
        
        // source
        current = cw
        // write include to the module's. h file
        current nl(). app("#include \""). app(module simpleName). app(".h\""). nl()
        
        // write all types
        for(tDecl: TypeDecl in module types) {
            printf("Writing type %s\n", tDecl name)
            tDecl accept(this)
        }
        
        // write all functions
        for(fDecl: FunctionDecl in module functions) {
            printf("Writing function %s\n", fDecl name)
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
