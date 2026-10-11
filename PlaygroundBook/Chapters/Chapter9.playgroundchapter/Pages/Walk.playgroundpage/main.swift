//#-hidden-code
import GameAPI
func _startGamePage() {
    let wire = GameWiring(.walk)
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
// // 👉 THIS PAGE: make ◀ walk left, and stop when no button is held.
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
// }
//
// // ========== ⚡ EVENTS ==========
// // Runs every frame you touch the 🚩.
// func playerTouchedFlag() {
//     game.win()
// }
//#-end-hidden-code
/*:
 # 1. Walk
 The engine redraws the game 60 times a second; each picture is a **frame**. You write **functions**, and the engine calls them for you: `startPlayer` once when the level starts, `updatePlayer` every frame, and the **event function** `playerTouchedFlag` when you touch the 🚩. Your functions change **speeds**: every frame, the engine moves you by `player.speedX`.

 ## Your turn
 - Holding ◀ walks left, as fast as ▶ walks right.
 - Holding no button stands still.
 - Walk to the 🚩.

 **Your tools:** `else if`, `isPressed(.left)`, `else`, `player.speedX`.

 **Controls:** tap the game once, then use the arrow keys, or hold the ◀ ▶ ▲ buttons.

 A 👉 comment marks where your code goes. The checklist above the game turns ✅ when your code works. Never put `while` in these functions: use `if`.

 Stuck? Open **Hints: Moving**. Still stuck? The next page has the finished code.
 */

// 👉 THIS PAGE: make ◀ walk left, and stop when no button is held.

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
    }
    // 👉 ◀ walks left. No button: stand still.

}

// ========== ⚡ EVENTS ==========
// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}
