
// sdk stuff
import io/File
import structs/[List, ArrayList, HashMap]

// our stuff
import rock/frontend/[BuildParams, Target]
import rock/frontend/drivers/SourceFolder
import rock/frontend/pkgconfig/[PkgInfo, PkgConfigFrontend]
import rock/middle/[Module, UseDef]

/**
 * Various flags that can be passed to the compiler/linker, classified
 * in two categories: compiler flags and linker flags.
 *
 * Well, there's a third category: it's "premain" flags, ie. stuff that
 * affects the way main is handled. For example, on Windows, -lmingw32
 * defines WinMain, which calls main, -lSDL2main defines main, which calls
 * SDL_main, and finally, sdl2-config passed compiler flags that renamed
 * your main function to SDL_main.
 *
 * An incorrect, naive command line would be:
 *
 *    gcc .libs\yourapp-win32.a -lmingw32 -lSDL2main -lSDL2
 *
 * This fails with 'Undefined reference to SDL_main'. Why? Because -lSDLmain
 * expects SDL_main to be defined in something passed somewhere later in the
 * linker arguments. But it's not, it's before.
 *
 * In fact, "-lmingw32 -lSDLmain" need to be passed before our main
 * object (or static library) file for this to work, ie. the correct
 * final command is:
 *
 *    gcc -lmingw32 -lSDL2main .libs\yourapp-win32.a -lSDL2
 *
 * This is correct because each item uses stuff that's later in the linker
 * arguments. -lmingw32 uses WinMain, -lSDL2main defines it and uses SDL_main,
 * defined in yourapp-win32.a, which itself uses many SDL functions, defind
 * in -lSDL2. All is well.
 *
 * :author: Amos Wenger (nddrylliog)
 */

Flags: class {

    customPkgCache := static HashMap<CustomPkg, PkgInfo> new()
  
    // flags
    compilerFlags := ArrayList<String> new()
    premainFlags := ArrayList<String> new()
    objects := ArrayList<String> new()
    linkerFlags := ArrayList<String> new()

    object, outPath: String
  
    modulesDone := ArrayList<Module> new()
    modulesDone := ArrayList<Module> new()
    usesDone := ArrayList<UseDef> new()
  
    init: func (=outPath) {
        addCompilerFlag("-std=gnu99")
        addCompilerFlag("-Wall")
    }
  
    absorb: func ~sourceFolder (sourceFolder: SourceFolder) {
        for(module in sourceFolder modules) {
            absorb(module)
        }
    }
  
    absorb: func ~module (module: Module) {
        if(modulesDone contains?(module)) {
           return
        }
        modulesDone add(module)

        for(uze in module getUses()) {
            absorb(uze useDef)
        }

        for(imp in module getAllImports()) {
            absorb(imp getModule())
        }
    }
  
    absorb: func ~useDef (useDef: UseDef) {
        if (!useDef) {
            // this workaround sucks, but sometimes useDef is null on Windows. Go figure.
            return
        }

        if (usesDone contains?(useDef)) {
            return
        }
        usesDone add(useDef)

        for (lib in useDef getLibs()) {
            addLinkerFlag(lib)
        }

        // OSX-only feature: frameworks
        if (Target guessHost() == Target OSX) {
            for(framework in useDef frameworks) {
                addLinkerFlag("-Wl,-framework," + framework)
            }
        }

        // handle pkg-config packages
        for(pkg in useDef getPkgs()) {
            absorb(PkgConfigFrontend getInfo(pkg))
        }

        // handle pkg-config-like packages (sdl2-config, etc.)
        for(pkg in useDef getCustomPkgs()) {
            info: PkgInfo
            if (customPkgCache contains?(pkg)) {
                info = customPkgCache get(pkg)
            } else {
                info = PkgConfigFrontend getCustomInfo(
                    pkg utilName, pkg names,
                    pkg cflagArgs, pkg libsArgs
                )
                customPkgCache put(pkg, info)
            }
            absorb(info)
        }

        // include paths
        for(includePath in useDef getIncludePaths()) {
            addCompilerFlag("-I" + includePath)
        }

        // library paths
        for(libPath in useDef getLibPaths()) {
            addLinkerFlag("-L" + libPath)
        }

        // .use file dependenceis
        for(req in useDef getRequirements()) {
            absorb(req useDef)
        }

    }

    absorb: func ~pkginfo (info: PkgInfo) {
        for(cflag in info cflags) {
            addCompilerFlag(cflag)
        }

        for(library in info libraries) {
            addLinkerFlag("-l" + library)
        }

        for(libPath in info libPaths) {
            addLinkerFlag("-L" + libPath)
        }
    }

    absorb: func ~params (params: BuildParams) {
        libsHeaders := File new(params distLocation, "libs/headers/") getPath()
        addCompilerFlag("-I" + libsHeaders)

        if (params libcache) {
            addCompilerFlag("-I" + params libcachePath)
        } else {
            addCompilerFlag("-I" + params outPath getPath())
        }

        for(define in params defines) {
            addCompilerFlag("-D" + define)
        }

        for(dynamicLib in params dynamicLibs) {
            addLinkerFlag("-l" + dynamicLib)
        }

        for(incPath in params incPath getPaths()) {
            addCompilerFlag("-I" + incPath getPath())
        }

        for(libPath in params libPath getPaths()) {
            addCompilerFlag("-L" + libPath getPath())
        }

        for(compilerArg in params compilerArgs) {
            addCompilerFlag(compilerArg)
        }
            
        if(params enableGC) {
            addLinkerFlag("-lpthread")

            if(params dynGC) {
                addLinkerFlag("-lgc")
            } else {
                arch := params arch equals?("") ? Target getArch() : params arch
                libPath := "libs/" + Target toString(arch) + "/libgc.a"
                addLinkerFlag(File new(params distLocation, libPath) path)
            }
        }
    }

    addCompilerFlag: func (flag: String) {
        flag = flag trim("\t ")
        if (!compilerFlags contains?(flag)) {
            compilerFlags add(flag)
        }
    }

    addLinkerFlag: func (flag: String) {
        flag = flag trim("\t ")
        if (!linkerFlags contains?(flag)) {
            linkerFlags add(flag)
        }
    }

    addObject: func (object: String) {
        object = object trim("\t ")
        if (!objects contains?(object)) {
            objects add(object)
        }
    }

    apply: func (command: List<String>) {
        if (objects empty?()) {
            Exception new(This, "No objects to compile!") throw()
        }

        command addAll(compilerFlags)
        command addAll(premainFlags)
        command addAll(objects)
        command add("-o" + outPath)
        command addAll(linkerFlags)
    }
  
}

