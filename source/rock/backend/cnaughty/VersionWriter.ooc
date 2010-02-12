import ../../middle/[Version]
import CGenerator

VersionWriter: abstract class extends CGenerator {

    writeStart: static func ~_version (this: This, _version: VersionSpec) {
        current nl(). app("#if ")
        _version write(current)
    }
    
    writeEnd: static func ~_version (this: This) {
        current nl(). app("#endif")
    }
    
}
