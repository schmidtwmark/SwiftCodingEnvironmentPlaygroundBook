// 👉 THIS PAGE: make ◀ walk left, and stop when no button is held.

// ========== 🙂 PLAYER ==========
// The player's start function. Runs once when the level starts, and again after every ouch.
func startPlayer(player: Player) {
    player.emoji = "🙂"   // your hero: try "🐱", "🤖" or "🦊"
}

// The player's update function. Runs 60 times a second.
func updatePlayer(player: Player) {
    // Walk:
    if isPressed(.right) {
        player.speedX = 6
    } else if isPressed(.left) {
        player.speedX = -6
    } else {
        player.speedX = 0
    }
    if isPressed(.up) {
        player.speedY = 6
    } else {
        player.speedY = 0
    }
}

// ========== ⚡ EVENTS ==========
// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}
