// MARK: Settings
game.skyColor = .hex("3a7bd5")
game.horizonColor = .hex("ffd194")

// A far layer: mountains.
game.addLayer("⛰️  🏔️   ⛰️ 🏔️    ", y: 0, size: 220, distance: 5)
// Step 2: a closer layer.

func startPlayer(player: Player) {
    game.addLayer("🌲 🌳🌲   🌲🌲 ", y: 64, size: 100, distance: 2)
}
