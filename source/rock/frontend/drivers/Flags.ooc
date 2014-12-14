
// sdk stuff
import io/File
import structs/[List, ArrayList, HashMap]

// our stuff
import rock/frontend/[BuildParams, Target]
import rock/frontend/drivers/[Archive, SourceFolder, CCompiler]
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
 */

Flags: class {

    customPkgCache := static HashMap<CustomPkg, PkgInfo> new()

    // pkgs
    pkgs := HashMap<String, String> new()

    // flags
    compilerFlags := ArrayList<String> new()
    premainFlags := ArrayList<String> new()
    objects := ArrayList<String> new()
    linkerFlags := ArrayList<String> new()

    outPath: String
    params: BuildParams

    modules := ArrayList<Module> new()
    mainModule: Module

    /* identifier => UseDef */
    uses := ArrayList<UseDef> new()

    sourceFolders := ArrayList<SourceFolder> new()

    doTargetSpecific := true

    init: func (=outPath, =params) {
        addCompilerFlag("-std=gnu99")
        addCompilerFlag("-Wall")
    }

    absorb: func ~sourceFolder (sourceFolder: SourceFolder) {
        if (sourceFolders contains?(sourceFolder)) {
            return
        }
        sourceFolders add(sourceFolder)

        for(module in sourceFolder modules) {
            absorb(module)
        }
    }

    absorb: func ~module (module: Module) {
        if(modules contains?(module)) {
           return
        }
        modules add(module)

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

        if (uses contains?(useDef)) {
            return
        }
        uses add(useDef)

        // .use file dependencies
        for(req in useDef requirements) {
            absorb(req useDef)
        }

        if (!doTargetSpecific) {
            // beyond this point, we have to do target-specific stuff
            // like call pkg-config, define which properties in version
            // blocks are 'relevant' and stuff - and we don't want to do that.
            return
        }

        props := useDef getRelevantProperties(params)

        for (lib in props libs) {
            addLinkerFlag(lib)
        }

        // OSX-only feature: frameworks
        if (params target == Target OSX) {
            for(framework in props frameworks) {
                addLinkerFlag("-Wl,-framework," + framework)
            }
        }

        // handle pkg-config packages
        for(pkg in props pkgs) {
            if (!pkgs contains?(pkg)) {
                pkgs put(pkg, pkg)
            }
            absorb(PkgConfigFrontend getInfo(pkg), useDef)
        }

        // handle pkg-config-like packages (sdl2-config, etc.)
        for(pkg in props customPkgs) {
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
            absorb(info, useDef)
        }

        // include paths
        for(includePath in props includePaths) {
            addCompilerFlag("-I" + includePath)
        }

        // library paths
        for(libPath in props libPaths) {
            addLinkerFlag("-L" + libPath)
        }

    }

    absorb: func ~pkginfo (info: PkgInfo, useDef: UseDef) {
        for(cflag in info compilerFlags) {
            addCompilerFlag(cflag)
        }

        for(lflag in info linkerFlags) {
            if (useDef preMains contains?(lflag)) {
                addPreMainFlag(lflag)
            } else {
                addLinkerFlag(lflag)
            }
        }
    }

    absorb: func ~params (params: BuildParams) {
        if (doTargetSpecific) {
            match (params profile) {
                case Profile DEBUG =>
                    addCompilerFlag("-g")
                    match (params target) {
                        case Target LINUX =>
                            // passes -export-dynamic to the linker, otherwise we
                            // can't have fancy backtraces.
                            if(params compiler executableName startsWith?("gcc")){
                                addCompilerFlag("-rdynamic")
                            }
                        case Target OSX =>
                            // disable position-independent execution (OSX's ASLR),
                            // otherwise we can't fine line info in our backtraces.
                            addCompilerFlag("-fno-pie")
                    }
            }
        }

        match (params optimization) {
            case OptimizationLevel O0 => addCompilerFlag("-O0")
            case OptimizationLevel O1 => addCompilerFlag("-O1")
            case OptimizationLevel O2 => addCompilerFlag("-O2")
            case OptimizationLevel O3 => addCompilerFlag("-O3")
            case OptimizationLevel Os => addCompilerFlag("-Os")
        }

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

        if (doTargetSpecific) {
            // 32 or 64 ?
            arch := params getArch()
            match arch {
                case "32" =>
                    addCompilerFlag("-m32")
                case "64" =>
                    addCompilerFlag("-m64")
            }
        }

        if(params enableGC) {
            vendorInclude := File join(params distLocation, "vendor-prefix", "include")
            addCompilerFlag("-I" + vendorInclude)

            vendorLib := File join(params distLocation, "vendor-prefix", "lib")
            addLinkerFlag("-L" + vendorLib)

            addLinkerFlag("-lgc")

            target := params target

            match target {
                case Target WIN =>
                    // The SDK doesn't use pthreads on Windows
                    addCompilerFlag("-mthreads")
                    addLinkerFlag("-mthreads")
                case Target OSX =>
                    // For OSX, -lpthread suffices, -pthread yields a warning
                    addLinkerFlag("-lpthread")
                case =>
                    // for other unices, -pthread is apparently a good idea.
                    // Some unices don't have a separate pthread library and it
                    // might do some other stuff (like define D_REENTRANT)
                    addCompilerFlag("-pthread")
                    addLinkerFlag("-pthread")
            }
        }
    }

    addCompilerFlag: func (flag: String) {
        flag = flag trim("\t ")
        if (flag == "") {
            return
        }

        if (!compilerFlags contains?(flag)) {
            compilerFlags add(flag)
        }
    }

    addLinkerFlag: func (flag: String) {
        flag = flag trim("\t ")
        if (flag == "") {
            return
        }

        if (!linkerFlags contains?(flag)) {
            linkerFlags add(flag)
        }
    }

    addPreMainFlag: func (flag: String) {
        flag = flag trim("\t ")
        if (flag == "") {
            return
        }

        if (!premainFlags contains?(flag)) {
            premainFlags add(flag)
        }
    }

    addObject: func ~archive (archive: Archive) {
        addObject(archive outlib)
    }

    addObject: func (object: String) {
        object = object trim("\t ")
        if (object == "") {
            return
        }

        if (!objects contains?(object)) {
            objects add(object)
        }
    }

    _applyFlags: func (flags: List<String>, command: List<String>) {
        for (flag in flags) {
            if (params bannedFlags contains?(flag))  {
                continue
            }
            command add(flag)
        }
    }

    apply: func (command: List<String>, link: Bool) {
        if (objects empty?()) {
            Exception new(This, "No objects to compile!") throw()
        }

        _applyFlags(compilerFlags, command)
        if (link) {
            _applyFlags(premainFlags, command)
        } else {
            command add("-c")
        }

        command addAll(objects)
        command add("-o"). add(outPath)

        if (link) {
            _applyFlags(linkerFlags, command)
        }
    }

    setMainModule: func (=mainModule)

}

