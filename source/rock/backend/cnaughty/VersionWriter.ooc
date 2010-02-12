import ../../middle/[Version]
import Skeleton

VersionWriter: abstract class extends Skeleton {

    writeStart: static func ~_version (this: This, _version: VersionSpec) {
        current nl(). app("#if ")
        _version write(current)
    }
    
    writeEnd: static func ~_version (this: This) {
        current nl(). app("#endif")
    }
    
}
