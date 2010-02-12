main: func {

    version(linux) {
        "Hello, Linux =)" println()
    }
    version(apple) {
        "Hello, Mac =)" println()
    }
    version(windows) {
        "Hello, Windows =)" println()
    }
    version(!linux) {
        version(!apple) {
            version(!windows) {
                "Hi, stranger ;)" println()
            }
        }
    }
    version(linux || apple)  {
        version(unix) {
            "Oh, wow, good vibes!" println()
        }
    }

}
