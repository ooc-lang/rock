RockVersion: class {
    execName := static ""

    getMajor:    static func -> Int    { 0 }
    getMinor:    static func -> Int    { 9 }
    getPatch:    static func -> Int    { 2 }
    getRevision: static func -> String { "head" }
    getName: static func -> String { getMajor() toString() + "." + getMinor() toString() + "." + getPatch() toString() + (getRevision() ? "-" + getRevision() : "") }
}