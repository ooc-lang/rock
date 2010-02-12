
version(unix) {

    Shouter: class {
        print: static func {
            "Unix !" println()
        }
    }

}

version(windows) {
    
    Shouter: class {
        print: static func {
            "Windows !" println()
        }
    }
    
}

version(apple) {
    
    Shouter: class {
        print: static func {
            "Mac !" println()
        }
    }
    
}

main: func {
    Shouter print()
}
