//#-hidden-code
import GameAPI
func _startGamePage() {
    let wire = GameWiring(.sparkles)
    wire.player(start: startPlayer(player:), update: updatePlayer(player:))
    wire.game(start: startGame(game:), update: updateGame(game:))
    wire.crab(start: startCrab(crab:), update: updateCrab(crab:))
    wire.bee(start: startBee(bee:), update: updateBee(bee:))
    wire.ghost(start: startGhost(ghost:), update: updateGhost(ghost:))
    wire.frog(start: startFrog(frog:), update: updateFrog(frog:))
    wire.fireball(start: startFireball(fireball:), update: updateFireball(fireball:))
    wire.touches(coin: playerTouchedCoin(coin:), enemy: playerTouchedEnemy(enemy:), flag: playerTouchedFlag,
                 spring: playerTouchedSpring(spring:), star: playerTouchedStar(star:))
    wire.events(playerGotHurt: playerGotHurt, fireballTouchedEnemy: fireballTouchedEnemy(fireball:enemy:))
    wire.start()
}
_startGamePage()
// MARK: - Solution
// // 👉 THIS PAGE: sparkles where you grab a coin, and a puff of dust when you jump.
//
// // ========== 🔢 VARIABLES ==========
// // A var up here, outside every function, keeps its number from frame to frame.
// // Coyote time: how many frames since you last stood on a block.
// var framesInAir = 0
//
// // ========== 🙂 PLAYER ==========
// // The player's start function. Runs once when the level starts, and again after every ouch.
// func startPlayer(player: Player) {
//     player.emoji = "🙂"   // your hero: try "🐱", "🤖" or "🦊"
// }
//
// // The player's update function. Runs 60 times a second.
// func updatePlayer(player: Player) {
//     // Walk:
//     if isPressed(.right) {
//         player.speedX = 6
//     } else if isPressed(.left) {
//         player.speedX = -6
//     } else {
//         player.speedX = 0
//     }
//     // Gravity:
//     player.speedY -= 1
//     // Coyote time: count the frames since you stood on a block.
//     if player.isOnGround() {
//         framesInAir = 0
//     } else {
//         framesInAir += 1
//     }
//     // Jump: from the ground, or up to 5 frames after you leave it.
//     if isPressed(.up) {
//         if framesInAir < 6 {
//             player.speedY = 18
//             framesInAir = 6   // used up: no second jump until you land
//             game.playSound(.jump)
//             player.burst("💨", count: 6, speed: 2)
//         }
//     }
// }
//
// // ========== 🎮 GAME ==========
// // The game's update function. Runs 60 times a second, after every other function.
// func updateGame(game: Game) {
//     game.showText("⭐ " + String(game.score))
// }
//
// // ========== ⚡ EVENTS ==========
// // Runs every frame you touch a 🪙. coin is that coin.
// func playerTouchedCoin(coin: Coin) {
//     game.score += 1
//     game.playSound(.coin)
//     coin.burst("✨")
//     coin.remove()
// }
//
// // Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
// func playerGotHurt() {
//     game.showMessage("Ouch!")
// }
//
// // Runs every frame you touch the 🚩.
// func playerTouchedFlag() {
//     game.win()
// }
//#-end-hidden-code
/*:
 # 8. Sparkles
 `burst` throws emoji out of a thing, and they fade in half a second: `player.burst("❤️", count: 20, speed: 8)`.

 ## Your turn
 - Sparkles ✨ come out of each coin you grab.
 - A small, slow puff of 💨 comes out of you on each jump: 6 of them, at speed 2.
 - Grab every coin in the sky to unlock the 🚩.

 **Your tools:** `burst`, and the two moments you found on Sounds.

 Stuck? Open **Hints: Coins and Effects**. Still stuck? **9. Crab Patrol** has the finished code.
 */

// 👉 THIS PAGE: sparkles where you grab a coin, and a puff of dust when you jump.

// ========== 🔢 VARIABLES ==========
// A var up here, outside every function, keeps its number from frame to frame.
// Coyote time: how many frames since you last stood on a block.
var framesInAir = 0

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
        }
    }
}

// ========== 🎮 GAME ==========
// The game's update function. Runs 60 times a second, after every other function.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
}

// ========== ⚡ EVENTS ==========
// Runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(coin: Coin) {
    game.score += 1
    game.playSound(.coin)
    coin.remove()
}

// Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.showMessage("Ouch!")
}

// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}
