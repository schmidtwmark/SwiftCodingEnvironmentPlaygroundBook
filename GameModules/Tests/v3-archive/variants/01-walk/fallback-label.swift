// The player's start script. Runs once when the level starts, and again after every ouch.
func startPlayer(player: Player) {
    player.emoji = "🙂"   // your hero: try "🐱", "🤖" or "🦊"
}

// The player's update script. Runs 60 times a second.
func updatePlayer(p: Player) {
    if isPressed(.right) {
        p.speedX = 6
    } else if isPressed(.left) {
        p.speedX = -6
    } else {
        p.speedX = 0
    }
}
