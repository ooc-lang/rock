
main: func {
    version (apple) {
        "Apple!" println()
    }

    version (ios_simulator) {
        "ios simulator!" println()
    }

    version (ios) {
        "ios!" println()
    }

    version (osx) {
        "OSX!" println()
    }
}
