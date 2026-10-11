// Event: runs every frame you touch a ⭐. star is that star.
func playerTouchedStar(star: Star) {
    star.remove()
    player.timer = 300
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
    // Star power counts down:
    if player.timer > 0 {
        player.emoji = "🤩"
    } else {
        player.emoji = "🙂"
    }
}

// Event: runs every frame you touch an enemy. enemy is that enemy.
func playerTouchedEnemy(enemy: Enemy) {
    if player.timer > 0 {
        // Star power: plow right through.
        enemy.remove()
    } else if player.speedY < 0 {
        // Falling onto it: squish it and bounce.
        enemy.remove()
        player.speedY = 12
    } else {
        // Walked into it: ouch!
        player.hurt()
    }
}
