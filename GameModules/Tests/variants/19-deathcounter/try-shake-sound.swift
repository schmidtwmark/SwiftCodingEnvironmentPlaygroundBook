// 👉 THIS PAGE: count every ouch, and show the count.

// ========== ⚙️ SETTINGS ==========
// The sky fades from skyColor (top) to horizonColor (bottom).
game.skyColor = .hex("3a7bd5")
game.horizonColor = .hex("ffd194")
// Layers far behind the level. A bigger distance scrolls slower.
game.addLayer("⛰️  🏔️   ⛰️ 🏔️    ", y: 0, size: 220, distance: 5)
game.addLayer("🌲 🌳🌲   🌲🌲 ", y: 64, size: 100, distance: 2)

// ========== 🔢 VARIABLES ==========
// A var up here, outside every function, keeps its number from frame to frame.
// Coyote time: how many frames since you last stood on a block.
var framesInAir = 0

// ========== 🙂 PLAYER ==========
// The player's start function. Runs once when the level starts, and again after every ouch.
func startPlayer(player: Player) {
    player.emoji = "🙂"   // your looks are now in "How you look", in updatePlayer
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
    // Coyote time: count the frames since you stood on a block.
    if player.isOnGround() {
        framesInAir = 0
    } else {
        framesInAir += 1
    }
    // Jump: from the ground, or up to 5 frames after you leave it.
    if isPressed(.up) {
        if framesInAir < 6 {
            player.speedY = 18
            framesInAir = 6   // used up: no second jump until you land
            game.playSound(.jump)
            player.burst("💨", count: 6, speed: 2)
        }
    }
    // How you look:
    if player.isOnGround() {
        if player.speedX == 0 {
            player.emoji = "🧍"
        } else {
            player.emoji = "🏃"
        }
    } else {
        player.emoji = "🤸"
    }
    // Star power: count down, and look like a star.
    if player.timer > 0 {
        player.timer -= 1
        player.emoji = "🤩"
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

// ========== 🎮 GAME ==========
// The game's update function. Runs 60 times a second, after every other function.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    // Stopwatch: count frames. 60 frames is 1 second.
    game.timer += 1
    game.showText("⏱ " + String(game.timer / 60))
    game.showText("💥 " + String(game.deaths))
}

// ========== 🦀 ENEMIES ==========
// Runs once for EACH 🦀 when the level starts, and again after every ouch. crab is that crab.
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

// ========== 🔥 FIREBALLS ==========
// Runs 60 times a second for EACH 🔥. fireball is the fireball whose turn it is.
func updateFireball(fireball: Fireball) {
    if fireball.facingWall() {
        fireball.remove()
    }
}

// ========== ⚡ EVENTS ==========
// Runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(coin: Coin) {
    game.score += 1
    game.playSound(.coin)
    coin.burst("✨")
    coin.remove()
}

// Runs every frame you touch a 🍄. spring is that spring.
func playerTouchedSpring(spring: Spring) {
    player.speedY = 25
}

// Runs every frame you touch a ⭐. star is that star.
func playerTouchedStar(star: Star) {
    star.remove()
    player.timer = 300
}

// Runs every frame you touch an enemy. enemy is that enemy.
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

// Runs every frame a 🔥 touches an enemy. fireball is that fireball; enemy is that enemy.
func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {
    enemy.remove()
    fireball.remove()
}

// Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.showMessage("Ouch! 💥 " + String(game.deaths))
    game.shake()
    game.playSound(.hurt)
    game.deaths += 1
}

// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}
