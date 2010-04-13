import ../../middle/[Version]
import Skeleton

VersionWriter: abstract class extends Skeleton {

    writeStart: static func ~_version (this: Skeleton, _version: VersionSpec) {
        current nl(). app("#if ")
        _version write(current)
    }
    
    writeEnd: static func ~_version (this: Skeleton) {
        current nl(). app("#endif")
    }
    
}
