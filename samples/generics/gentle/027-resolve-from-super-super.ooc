Turret: class <KABOOM> {
    
    
    
}

AntiAir: class <KABOOM> extends Turret<KABOOM> {
    
    
    
}

VMH: class extends AntiAir<Int> {
    
    print: static func {
        "Oh, we're so a VMH of %s" format(KABOOM name) println()
        /*
        i: KABOOM
        i = 42
        "Hey, the answer is %d\n" format(i) println()
        */
    }
    
}


main: func {
    
    VMH print()
    
}