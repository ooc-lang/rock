import io/File, structs/[ArrayList, HashMap], os/[Process, Env]
import os/ShellUtils
import PkgInfo

/**
 * A frontend to pkgconfig, to retrieve information for packages,
 * like gtk+-2.0, gtkgl-2.0, or imlib2
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

        cflags := ""

        for (cflagArg in cflagArgs) {
            cflagslist := [utilPath] as ArrayList<String>
            cflagslist addAll(pkgs)
            cflagslist add(cflagArg)
            result := _shell(cflagslist)
            if(!cflags) {
                Exception new("Error while running `%s`" format(cflagslist join(" "))) throw()
            }

            cflags += result
            cflags += " "
        }

        libs := ""

        for (libsArg in libsArgs) {
            libslist := [utilPath] as ArrayList<String>
            libslist addAll(pkgs)
            libslist add(libsArg)
            result := _shell(libslist)
            if(result == null) {
                Exception new("Error while running `%s`" format(libslist join(" "))) throw()
            }
            libs += result
            libs += " "
        }

        PkgInfo new(pkgs join(" "), libs, cflags)
    }

    _shell: static func (command: ArrayList<String>) -> String {
        try {
            (output, exitCode) := Process new(command) getOutput()

            if (exitCode != 0) {
                ProcessException new(This, "Couldn't execute a pkg-config like utility")
            }

            return output trim(" \r\n")
        } catch (pe: ProcessException) {
            // Failed to execute, maybe it's a shell script?
            // Note that this has only been witnessed on MSYS/MinGW

            shellCommand := ArrayList<String> new()
            shellCommand add("sh")
            shellCommand addAll(command)
            (output, exitCode) := Process new(shellCommand) getOutput()

            if (exitCode == 0) {
                return output trim(" \r\n")
            }
        }

        return null
    }

}
