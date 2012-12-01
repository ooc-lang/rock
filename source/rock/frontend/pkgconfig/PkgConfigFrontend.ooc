import io/File, structs/[ArrayList, HashMap], os/[Process, Env]
import ../../utils/ShellUtils
import PkgInfo

/**
 * A frontend to pkgconfig, to retrieve information for packages,
 * like gtk+-2.0, gtkgl-2.0, or imlib2
 * @author nddrylliog aka Amos Wenger
 */
PkgConfigFrontend: class {

    cache := static HashMap<String, PkgInfo> new()

    /**
     *
     * @param pkgName
     * @return the information concerning a package managed by pkg-manager
     */
    getInfo: static func (pkgName: String) -> PkgInfo {
        // Note: we only cache the most common names: pkg-config packages
        pkg: PkgInfo
        pkg = cache get(pkgName)
        if (!pkg) {
            pkg = getCustomInfo(
                "pkg-config", [pkgName] as ArrayList<String>,
                ["--cflags"] as ArrayList<String>,
                ["--libs"] as ArrayList<String>)
            cache put(pkgName, pkg)
        }
        pkg
    }

    getCustomInfo: static func (utilName: String, pkgs: ArrayList<String>,
        cflagArgs: ArrayList<String>, libsArgs: ArrayList<String>) -> PkgInfo {
        utilPath := ShellUtils findExecutable(utilName, true) getPath()

        cflagslist := [utilPath] as ArrayList<String>
        cflagslist addAll(pkgs)
        cflagslist addAll(cflagArgs)
        cflags := _shell(cflagslist)

        if(cflags == null) {
            Exception new("Error while running `%s`" format(cflagslist join(" "))) throw()
        }

        libslist := [utilPath] as ArrayList<String>
        libslist addAll(pkgs)
        libslist addAll(libsArgs)
        libs := _shell(libslist)

        if(libs == null) {
            Exception new("Error while running `%s`" format(libslist join(" "))) throw()
        }

        PkgInfo new(pkgs join(" "), libs, cflags)
    }

    _shell: static func (command: ArrayList<String>) -> String {
        Process new(command) getOutput() trim(" \n")
    }

}
