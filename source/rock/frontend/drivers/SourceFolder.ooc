
// sdk stuff
import structs/ArrayList, io/File

// our stuff
import rock/middle/Module
import rock/frontend/[BuildParams, Target]
import rock/frontend/drivers/Archive

/**
 * A source folder corresponds to an ooc 'library' or 'project', if
 * you will.
 *
 * It usually corresponds to one use file - when it doesn't, it's because
 * we're compiling from one main .ooc file.
 *
 * :author: Amos Wenger (nddrylliog)
 */
SourceFolder: class {

    // example: foo
    identifier: String
    
    // usually "source", per ooc conventions
    name: String

    // typically "$OOC_LIBS/<identifier>/source"
    pathElement: String
    
    // absolute variant of pathElement
    absolutePath: String

    // example: .libs/foo-win32.a
    outlib: String

    params: BuildParams
    archive: Archive
    modules := ArrayList<Module> new()

    init: func (=name, =pathElement, =identifier, =params) {
        absolutePath = File new(pathElement) getAbsolutePath()

        // example: .libs/foo-win32.a
        archivePath := "%s-%s.a" format(identifier, Target toString())
        outlib = File new(params libcachePath, archivePath) getPath()

        // archive will cache info as .libs/foo-win32.a.cacheinfo
        archive = Archive new(identifier, outlib, params, true, File new(absolutePath))
    }

    includePath: func -> String {
        params libcachePath + File separator + identifier
    }

}
