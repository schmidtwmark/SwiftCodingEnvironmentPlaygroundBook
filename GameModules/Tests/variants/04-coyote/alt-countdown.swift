// 👉 THIS PAGE: you can still jump for a moment after you run off a ledge.

// ========== 🔢 VARIABLES ==========
// A var up here, outside every function, keeps its number from frame to frame.
// Coyote time: how many frames since you last stood on a block.
var framesInAir = 0
var coyoteLeft = 0

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
    // Gravity:
    player.speedY -= 1
    // Coyote time: frames left to jump.
    if player.isOnGround() {
        coyoteLeft = 6
    } else if coyoteLeft > 0 {
        coyoteLeft -= 1
    }
    // Jump:
    if isPressed(.up) {
        if coyoteLeft > 0 {
            player.speedY = 18
            coyoteLeft = 0
        }
    }
}

// ========== ⚡ EVENTS ==========
// Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.showMessage("Ouch!")
}

// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}
