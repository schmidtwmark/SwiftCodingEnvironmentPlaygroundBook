//#-hidden-code
import GameAPI
func _startGamePage() {
    let wire = GameWiring(.coins)
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
// // 👉 THIS PAGE: every coin adds 1 to the score, once, and disappears.
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
//         }
//     }
// }
//
// // ========== ⚡ EVENTS ==========
// // Runs every frame you touch a 🪙. coin is that coin.
// func playerTouchedCoin(coin: Coin) {
//     game.score += 1
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
 # 5. Coins
 **Event functions** run when something happens. The engine calls `playerTouchedCoin` on every frame you touch a 🪙, and hands it **that coin**: `coin`.

 ## Your turn
 - Every coin adds 1 to `game.score`, once, and disappears.
 - Collect all 6 coins to unlock the 🚩.

 **Your tools:** `game.score`, `+=`, the coin's `remove()`.

 Stuck? Open **Hints: Coins and Effects**. Still stuck? The next page has the finished code.
 */

// 👉 THIS PAGE: every coin adds 1 to the score, once, and disappears.

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
        }
    }
}

// ========== ⚡ EVENTS ==========
// Runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(coin: Coin) {

}

// Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.showMessage("Ouch!")
}

// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}
