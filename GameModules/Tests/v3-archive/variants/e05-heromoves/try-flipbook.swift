var runFrames = 0

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
    // Jump (only from the ground):
    if isPressed(.up) {
        if player.isOnGround() {
            player.speedY = 18
        }
    }
    // How you look:
    if player.isOnGround() {
        if player.speedX == 0 {
            player.emoji = "🧍"
        } else {
            runFrames += 1
            if runFrames == 16 {
                runFrames = 0
            }
            if runFrames < 8 {
                player.emoji = "🏃"
            } else {
                player.emoji = "🚶"
            }
        }
    } else {
        player.emoji = "🤸"
    }
    if player.speedY < -15 {
        player.emoji = "😱"
    }
}
