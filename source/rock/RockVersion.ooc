
RockVersion: class {
    execName := static ""

    getMajor:    static func -> Int    { 0 }
    getMinor:    static func -> Int    { 9 }
    getPatch:    static func -> Int    { 2 }
    getRevision: static func -> String { "head" }
    getName: static func -> String { "%d.%d.%d%s" format(
        getMajor(), getMinor(), getPatch(), (getRevision() ? "-" + getRevision() : "")) }
}