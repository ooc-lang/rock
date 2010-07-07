import structs/ArrayList
import frontend/CommandLine

Rock: class {
    execName := static ""

    getVersionMajor:    static func -> Int    { 0 }
    getVersionMinor:    static func -> Int    { 9 }
    getVersionPatch:    static func -> Int    { 2 }
    getVersionRevision: static func -> String { "head" }
    getVersionName: static func -> String { "%d.%d.%d%s" format(
        getVersionMajor(), getVersionMinor(), getVersionPatch(), getVersionRevision() ? "-" + getVersionRevision() : "") }
}

main: func(args: ArrayList<String>) {

    Rock execName = args[0]
    CommandLine new(args)

}
