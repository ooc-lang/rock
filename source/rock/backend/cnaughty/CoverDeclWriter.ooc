import structs/[List, ArrayList, HashMap]
import ../../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl, Type, Node, CoverDecl]
import Skeleton, FunctionDeclWriter, TypeWriter, ClassDeclWriter

CoverDeclWriter: abstract class extends Skeleton {

    write: static func ~_cover (this: This, cDecl: CoverDecl) {
        
        current = hw

		// addons only add functions to an already imported cover, so
		// we don't need to struct it again, it would confuse the C compiler
		if(!cDecl isAddon() && !cDecl isExtern() && cDecl fromType == null) {
            writeGuts(this, cDecl)
		}
        
		for(fDecl in cDecl functions) {
			fDecl accept(this)
            current nl()
		}
        
        for(interfaceDecl in cDecl getInterfaceDecls()) {
            ClassDeclWriter write(this, interfaceDecl)
        }
        
    }
    
    writeGuts: static func (this: This, cDecl: CoverDecl) {
        
        current nl(). app("struct _"). app(cDecl underName()). app(' '). openBlock()
        for(vDecl in cDecl variables) {
            current nl()
            if(!vDecl isExtern()) {
                current app(vDecl type). app(' '). app(vDecl name). app(";")
            }
        }
        current closeBlock(). app(';'). nl()
        
    }
    
    writeTypedef: static func (this: This, cDecl: CoverDecl) {
		
		if(!cDecl isAddon() && !cDecl isExtern()) {
			fromType := cDecl fromType
			if(!fromType) {
				current nl(). app("typedef struct _"). app(cDecl underName()).
					app(' '). app(cDecl underName()). app(';')
			} else {
				current nl(). app("typedef ")
				//if(fromType class instanceof (FuncType)) {
					//TypeWriter writeFuncPointer(this, ((FuncType) fromType).getDecl(), cDecl getName());
				//} else {
					current app(fromType getGroundType()). app(' '). app(cDecl underName())
				//}
				current app(';')
			}
		}
        
	}
    
}

