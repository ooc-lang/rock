
RockVersion: class {
    execName := static ""

    getMajor:    static func -> Int    { 1 }
    getMinor:    static func -> Int    { 0 }
    getPatch:    static func -> Int    { 0 }
    getRevision: static func -> String { "specialize" }
    getName: static func -> String { "%d.%d.%d%s" format(
        getMajor(), getMinor(), getPatch(), (getRevision() ? "-" + getRevision() : "")) }
}
