
RockVersion: class {
    execName := static ""

    getMajor:    static func -> Int    { 0 }
    getMinor:    static func -> Int    { 9 }
    getPatch:    static func -> Int    { 5 }
    getRevision: static func -> String { null }
    getCodename: static func -> String { "panda" }

    getName: static func -> String { "%d.%d.%d%s codename %s" format(
        getMajor(), getMinor(), getPatch(), (getRevision() ? "-" + getRevision() : ""),
        getCodename()) }
}
