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
		
        cached := This cache get(pkgName)
		if(cached != null) {
			return cached
		}
		
        path   := getPkgConfigPath()
        if(path == null) {
            Exception new("Error! the 'pkg-config' tool, necessary to resolve package '%s' couldn't be find in the $PATH, which is %s" format(pkgName, Env get("PATH"))) throw()
        }
        
        libs   := Process new([path getPath(), pkgName, "--libs"  ] as ArrayList<String>) getOutput() trim(" \n")
		cflags := Process new([path getPath(), pkgName, "--cflags"] as ArrayList<String>) getOutput() trim(" \n")
		if(libs == null) {
			Exception new("Can't find package '%s' in PKG_CONFIG_PATH. Have you configured pkg-config correctly?" format(pkgName)) throw()
		}
        
        pkgInfo := PkgInfo new(pkgName, libs, cflags)
		This cache put(pkgName, pkgInfo)
		pkgInfo
		
	}
    
    getPkgConfigPath: static func -> File {
        path : static File = null
        if(!path) {
            path = ShellUtils findExecutable("pkg-config", false)
        }
        return path
    }
	
}
