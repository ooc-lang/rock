import structs/[List, ArrayList, HashMap]
import ../middle/[ClassDecl, FunctionDecl, VariableDecl, TypeDecl, Type, Node, Line, CoverDecl]
import Skeleton, FunctionDeclWriter, TypeWriter

CoverDeclWriter: abstract class extends Skeleton {

    write: static func ~_cover (this: This, cDecl: CoverDecl) {
        
        current = hw

		// addons only add functions to an already imported cover, so
		// we don't need to struct it again, it would confuse the C compiler
		if(!cDecl isAddon() && !cDecl isExtern() && cDecl fromType == null) {
            current nl(). app("struct _"). app(cDecl underName()). app(' '). openBlock()
			for(vDecl in cDecl variables) {
				current nl()
                if(!vDecl isExtern()) {
                    current app(vDecl type). app(' '). app(vDecl name). app(";")
                }
			}
			current closeBlock(). app(';'). nl()
		}
		
		for(fDecl in cDecl functions) {
			fDecl accept(this)
            current nl()
		}
        
        writeClassFunction(this, cDecl)
        
    }
    
    writeClassFunction: static func (this: This, cDecl: CoverDecl) {
        
        current = fw
        
        current nl() .app("lang__Class *"). app(cDecl name). app("_class();")
        
        current = cw
        
        current nl().
        app("lang__Class *"). app(cDecl name). app("_class() {"). tab(). nl().
            app("static lang__Class _class = {"). tab(). nl().
                app(".size = sizeof("). app(cDecl underName()). app("),"). nl().
                app(".instanceSize = sizeof("). app(cDecl underName()). app("),"). nl().
                app(".name = \""). app(cDecl name). app("\"").
            untab(). nl(). app("};").
            nl(). app("return &_class;").
        untab(). nl(). app("}").
        nl()
        
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
					TypeWriter writeSpaced(this, fromType getGroundType(), true)
					current app(cDecl underName())
				//}
				current app(';')
			}
		}
        
	}
    
}

