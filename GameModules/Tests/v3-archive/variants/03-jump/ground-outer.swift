// The player's start script. Runs once when the level starts, and again after every ouch.
func startPlayer(player: Player) {
    player.emoji = "🙂"   // your hero: try "🐱", "🤖" or "🦊"
}

// The player's update script. Runs 60 times a second.
func updatePlayer(player: Player) {
    if isPressed(.right) {
        player.speedX = 6
    } else if isPressed(.left) {
        player.speedX = -6
    } else {
        player.speedX = 0
    }
    // Gravity:
    player.speedY -= 1
    if player.isOnGround() {
        if isPressed(.up) {
            player.speedY = 18
        }
    }
}
