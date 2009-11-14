

// long syntax

[1, 2, 3] each(func (val: Int) {
    printf("%d\n", val)
})

// short syntax

[1, 2, 3] each( |val|
    printf("%d\n", val)
)

// overloaded each method example for maps

info := ["name" => "Bugs", "surname" => "Bunny"]
info each ( |key, val|
    printf("%s = %s\n", key, val)
)
