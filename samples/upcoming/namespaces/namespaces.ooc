import lifeforms
using Animals


test: func {
    using Plants, Fungi

    // Flower is part of Plants namespace
    flower := Flower new()

    // Dog is part of Animals namespace
    dog := Dog new()

    // Mold is part of Fungi namespace
    mold := Mold new()
}

main: func {
    // Horse is part of Animals namespace
    horse := Horse new()

    // Tree is part of Plants namespace
    tree := Plants Tree new()
}
