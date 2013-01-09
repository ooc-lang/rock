
// sdk stuff
import structs/[ArrayList, List]
import text/StringTokenizer

/**
 * Information about a package managed by pkg-config
 *
 * :author: Amos Wenger (nddrylliog)
 */
PkgInfo: class {

    /** The name of the package, e.g. gtk+-2.0, or imlib2 */
    name: String
	
    /** The output of `pkg-config --cflags name` */
    compilerFlags := ArrayList<String> new()
	
    /** The output of `pkg-config --libs name` */
    linkerFlags := ArrayList<String> new()
	
    init: func (=name, libsString, cflagsString: String) {
        compilerFlags addAll(split(cflagsString)) 
        linkerFlags   addAll(split(libsString)) 

        printEach := func (list: ArrayList<String>) {
            list each(|f|
                "size %d, first char %d, '%s'" printfln(f size, f[0], f)
            )
        }

        "For %s, got compiler flags:" printfln(name)
        printEach(compilerFlags)

        "For %s, got linker flags:" printfln(name)
        printEach(linkerFlags)
    }

    split: func (line: String) -> List<String> {
        line split(' ', false) \
             map(|f| f trim(" \t")) \
             filter(|f| !f empty?())
    }
	
}
