// MARK: Your level
game.level = """
..........................................
...~...........~....g......~..............
..........................................
.............ooo..........................
............#####.....b...................
..........................................
........###...............#....ooo........
..P...#........c...#..^^..#...#####..f...F
##########################################
"""

// MARK: Settings
game.background = .day   // try .sunset, .night, .space (Extra: Backgrounds)
game.showNumbers = true   // the inspector; false for a finished game

// MARK: Scripts
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
    if player.isOnGround() { player.emoji = "🧍" } else { player.emoji = "🤸" }
    // ▼ throws a fireball the way you face:
    if justPressed(.down) {
        if player.facingRight() {
            game.spawn(.fireball, x: player.x, y: player.y, speedX: 12, speedY: 0)
        } else {
            game.spawn(.fireball, x: player.x, y: player.y, speedX: -12, speedY: 0)
        }
    }
}

// The game's start script. Runs once when the game starts, and again when it starts over (after game over, or when you play again after a win).
func startGame(game: Game) {

}

// The game's update script. Runs 60 times a second, after every other script.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}

// Event: runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(coin: Coin) {
    game.score += 1
    coin.remove()
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

// Runs 60 times a second for EACH 🐝. bee is the bee whose turn it is.
func updateBee(bee: Bee) {
    // Up for 1 second, then down:
    if bee.timer < 60 {
        bee.speedY = 2
    } else {
        bee.speedY = -2
    }
    // Count frames. 60 frames is 1 second:
    bee.timer += 1
    // Start over after 2 seconds:
    if bee.timer == 120 {
        bee.timer = 0
    }
}

// Runs 60 times a second for EACH 👻. ghost is the ghost whose turn it is.
// Ghosts float right through blocks.
func updateGhost(ghost: Ghost) {
    // Chase left and right:
    if player.x > ghost.x {
        ghost.speedX = 1
    } else {
        ghost.speedX = -1
    }
    // Chase up and down:
    if player.y > ghost.y {
        ghost.speedY = 1
    } else {
        ghost.speedY = -1
    }
}

// Runs 60 times a second for EACH 🐸. frog is the frog whose turn it is.
func updateFrog(frog: Frog) {
    // Gravity:
    frog.speedY -= 1
    // Count frames, and hop every 90 frames:
    frog.timer += 1
    if frog.timer == 90 {
        frog.speedY = 14
        frog.timer = 0
    }
}

// Event: runs every frame you touch an enemy. enemy is that enemy.
func playerTouchedEnemy(enemy: Enemy) {
    if player.speedY < 0 {
        // Falling onto it: squish it and bounce.
        enemy.remove()
        player.speedY = 12
    } else {
        // Walked into it: ouch!
        player.hurt()
    }
}

// Event: runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.showMessage("Ouch!")
}

// Event: runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}

// Runs 60 times a second for EACH 🔥. fireball is the fireball whose turn it is. (Already done: it disappears at a wall.)
func updateFireball(fireball: Fireball) {
    if fireball.facingWall() {
        fireball.remove()
    }
}

// Event: runs every frame a 🔥 touches an enemy. fireball is that fireball; enemy is that enemy.
func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {
    enemy.remove()
    fireball.remove()
}
