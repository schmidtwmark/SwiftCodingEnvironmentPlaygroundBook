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
            game.playSound(.jump)
        }
    }
}

// Event: runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(c: Coin) {
    game.score += 1
    game.playSound(.coin)
    c.remove()
}
