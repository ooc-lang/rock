Container: class <T> {

    goldkey : String
    hoobadoo : T
    
    init: func (=goldkey, .hoobadoo) {
        this hoobadoo = hoobadoo
    }
    
}

main: func {
    
    c := Container<Int> new("Yeppo", 42)
    
}
