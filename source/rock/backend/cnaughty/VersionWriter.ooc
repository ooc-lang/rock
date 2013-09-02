import ../../middle/[Version]
import Skeleton

VersionWriter: abstract class extends Skeleton {

    writeStart: static func ~_version (this: Skeleton, _version: VersionSpec) {
        if (_version spec && _version spec prelude) {
            current nl(). app(_version spec prelude)
        }
        current nl(). app("#if ")
        _version write(current)
    }

    writeEnd: static func ~_version (this: Skeleton, _version: VersionSpec) {
        current nl(). app("#endif")
        if (_version spec && _version spec afterword) {
            current nl(). app(_version spec afterword)
        }
    }

}
