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
    // ▼ throws a fireball the way you face:
    if justPressed(.down) {
        if player.facingRight() {
            game.spawn(.fireball, x: player.x, y: player.y, speedX: 12, speedY: 0)
        } else {
            game.spawn(.fireball, x: player.x, y: player.y, speedX: -12, speedY: 0)
        }
    }
}

// Runs 60 times a second for EACH 🔥. fireball is the fireball whose turn it is. (Already done: it disappears at a wall.)
func updateFireball(fireball: Fireball) {
    fireball.speedY -= 1
    if fireball.isOnGround() {
        fireball.speedY = 8
    }
    if fireball.facingWall() {
        fireball.remove()
    }
}

// Event: runs every frame a 🔥 touches an enemy. fireball is that fireball; enemy is that enemy.
func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {
    game.spawn(.coin, x: enemy.x, y: enemy.y + 64)
    enemy.remove()
    fireball.remove()
    game.playSound(.laser)
}
