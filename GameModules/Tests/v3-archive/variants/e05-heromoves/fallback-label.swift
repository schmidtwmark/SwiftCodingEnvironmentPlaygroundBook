// The player's update script. Runs 60 times a second.
func updatePlayer(p: Player) {
    if isPressed(.right) {
        p.speedX = 6
    } else if isPressed(.left) {
        p.speedX = -6
    } else {
        p.speedX = 0
    }
    // Gravity:
    p.speedY -= 1
    // Jump (only from the ground):
    if isPressed(.up) {
        if p.isOnGround() {
            p.speedY = 18
        }
    }
    // How you look:
    if p.isOnGround() {
        if p.speedX == 0 {
            p.emoji = "🧍"
        } else {
            p.emoji = "🏃"
        }
    } else {
        p.emoji = "🤸"
    }
}
