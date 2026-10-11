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
    // Jump (only from the ground):
    if isPressed(.up) {
        if player.isOnGround() {
            player.speedY = 18
        }
    }
}

// Event: runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(coin: Coin) {
    game.score += 1
    coin.remove()
}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}

// Runs once for EACH 🦀 when the level starts, and again after every ouch.
// crab is that crab.
func startCrab(crab: Crab) {
    crab.speedX = -2
}

// Runs 60 times a second for EACH 🦀. crab is the crab whose turn it is.
func updateCrab(crab: Crab) {
    if crab.facingWall() {
        crab.speedX = -crab.speedX
    }
}

// Runs 60 times a second for EACH 🐝.
func updateBee(bee: Bee) {
    if bee.timer < 60 {
        bee.speedY = 2
    }
    bee.timer += 1
    if bee.timer == 120 {
        bee.timer = 0
    }
}
