
import rock/middle/[Module, TypeDecl, CoverDecl, Import]

/**
 * Classify imports between 'tight' (include .h) and
 * 'loose' (include -fwd.h).
 */
ImportClassifier: class {

    classify: static func (module: Module) {
        imports := module getAllImports()

        for(selfDecl in module getTypes()) {
            for(imp in imports) {
                if(selfDecl getSuperRef() != null && selfDecl getSuperRef() getModule() == imp getModule()) {
                    // tighten imports of modules which contain classes we extend
                    imp isTight = true
                } else if(imp getModule() types getKeys() contains?("Class")) {
                    // tighten imports of core module
                    imp isTight = true
                } else {
                    for(member in selfDecl getVariables()) {
                        ref := member getType() getRef()
                        if(!ref instanceOf?(CoverDecl)) continue
                        coverDecl := ref as CoverDecl
                        if(coverDecl getFromType() != null) continue
                        if(coverDecl getModule() != imp getModule()) continue
                        // uses compound cover, tightening!
                        imp isTight = true
                        continue
                    }
                    for(interfaceType in selfDecl interfaceTypes) {
                        if(interfaceType getRef() as TypeDecl getModule() == imp getModule()) {
                            imp isTight = true
                            break
                        }
                    }
                }
            }
        }
    }

}

