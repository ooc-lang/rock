
fails := false

main: func {
    one()

    if (fails) {
        "We've had failures" println()
        exit(1)
    }

    "Pass!" println()
}

TileId: cover from UInt

one: func {
    // no value to check here
    (row, column) := getTileRowColumn(256 as TileId)
}

getTileRowColumn: func (lid: TileId) -> (SizeT, SizeT) {
    tilesPerRow: SizeT = 42
    (lid / tilesPerRow, lid % tilesPerRow)
}

