
// sdk stuff
import structs/ArrayList, io/File

// our stuff
import rock/middle/[Module, UseDef]
import rock/frontend/[BuildParams, Target]
import rock/frontend/drivers/Archive

/**
 * A source folder corresponds to an ooc 'library' or 'project', if
 * you will.
 *
 * It usually corresponds to one use file - when it doesn't, it's because
 * we're compiling from one main .ooc file.
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

    // the UseDef that specified this SourceFolder
    uze: UseDef

    init: func (=name, =pathElement, =identifier, =params, =uze) {
        absolutePath = File new(pathElement) getAbsolutePath()

        // example: .libs/foo-win32.a
        target := params target
        arch := params getArch()
        archivePath := "%s-%s.a" format(identifier, Target toString(target, arch))
        outlib = File new(params libcachePath, archivePath) path

        // archive will cache info as .libs/foo-win32.a.cacheinfo
        archive = Archive new(this, outlib, params, true, File new(absolutePath))
    }

    relativeObjectPath: func (module: Module) -> String {
        File new(identifier, module path + ".o") getPath()
    }

}
