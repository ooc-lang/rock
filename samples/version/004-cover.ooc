
version(unix) {

    Shouter: cover {
        print: static func {
            "Unix !" println()
        }
    }

}

version(windows) {
    
    Shouter: cover {
        print: static func {
            "Windows !" println()
        }
    }
    
}

version(apple) {
    
    Shouter: cover {
        print: static func {
            "Mac !" println()
        }
    }
    
}

main: func {
    Shouter print()
}
