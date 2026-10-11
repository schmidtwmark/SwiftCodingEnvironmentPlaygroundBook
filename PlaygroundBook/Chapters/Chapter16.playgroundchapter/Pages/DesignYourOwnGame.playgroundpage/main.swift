//#-hidden-code
import GameAPI
func _startGamePage() {
    let wire = GameWiring(.design)
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
// // 👉 THIS PAGE: your game. Change anything!
//
// // ========== 🗺️ LEVELS ==========
// // Level 1: your map. Each line is one row of squares.
// game.level = """
// ..........................................
// ...~...........~....g......~..............
// ..........................................
// .............ooo..........................
// ............#####.....b...................
// ..........................................
// ........###...............#....ooo........
// ..P...#..*.....c...#..^^..#.s.#####..f...F
// ##########################################
// """
//
// // Level 2: the map you play after level 1's 🚩. Each line is one row of squares.
// game.level2 = """
// ..............................
// ...~..........~...........~...
// ..............................
// ..............................
// ..............................
// ......o..ooo.......o..........
// ........#####.................
// .P...#..............c...#.c..F
// ##############..##############
// """
//
// // ========== ⚙️ SETTINGS ==========
// // The sky fades from skyColor (top) to horizonColor (bottom).
// game.skyColor = .hex("2b1b4a")
// game.horizonColor = .hex("ff8a5c")
// game.ghostEmoji = "🦇"
// // Layers far behind the level. A bigger distance scrolls slower.
// game.addLayer("⛰️  🏔️   ⛰️ 🏔️    ", y: 0, size: 220, distance: 5)
// game.addLayer("🌲 🌳🌲   🌲🌲 ", y: 64, size: 100, distance: 2)
//
// // ========== 🔢 VARIABLES ==========
// // A var up here, outside every function, keeps its number from frame to frame.
// // Coyote time: how many frames since you last stood on a block.
// var framesInAir = 0
//
// // ========== 🙂 PLAYER ==========
// // The player's start function. Runs once when the level starts, and again after every ouch.
// func startPlayer(player: Player) {
//     player.emoji = "🦊"
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
//     // How you look:
//     player.emoji = "🦊"
//     // Star power: count down, and look like a star.
//     if player.timer > 0 {
//         player.timer -= 1
//         player.emoji = "🤩"
//     }
//     // ▼ throws a fireball the way you face:
//     if justPressed(.down) {
//         if player.facingRight() {
//             game.spawn(.fireball, x: player.x, y: player.y, speedX: 12, speedY: 0)
//         } else {
//             game.spawn(.fireball, x: player.x, y: player.y, speedX: -12, speedY: 0)
//         }
//     }
// }
//
// // ========== 🎮 GAME ==========
// // The game's start function. Runs once when the game starts, and again when it starts over
// // (after game over, or when you play again after a win).
// func startGame(game: Game) {
//     game.lives = 3
// }
//
// // The game's update function. Runs 60 times a second, after every other function.
// func updateGame(game: Game) {
//     game.showText("⭐ " + String(game.score))
//     // Stopwatch: count frames. 60 frames is 1 second.
//     game.timer += 1
//     game.showText("⏱ " + String(game.timer / 60))
//     game.showText("💥 " + String(game.deaths))
//     game.showText("❤️ " + String(game.lives))
// }
//
// // ========== 🦀 ENEMIES ==========
// // Runs once for EACH 🦀 when the level starts, and again after every ouch. crab is that crab.
// func startCrab(crab: Crab) {
//     crab.speedX = -2
// }
//
// // Runs 60 times a second for EACH 🦀. crab is the crab whose turn it is.
// func updateCrab(crab: Crab) {
//     if crab.facingWall() {
//         crab.speedX = -crab.speedX
//     }
// }
//
// // Runs 60 times a second for EACH 🐝. bee is the bee whose turn it is.
// func updateBee(bee: Bee) {
//     // Up for 1 second, then down:
//     if bee.timer < 60 {
//         bee.speedY = 2
//     } else {
//         bee.speedY = -2
//     }
//     // Count frames. 60 frames is 1 second:
//     bee.timer += 1
//     // Start over after 2 seconds:
//     if bee.timer == 120 {
//         bee.timer = 0
//     }
// }
//
// // Runs 60 times a second for EACH 👻. ghost is the ghost whose turn it is.
// // Ghosts float right through blocks.
// func updateGhost(ghost: Ghost) {
//     // A bat: it chases only when you're close.
//     ghost.speedX = 0
//     ghost.speedY = 0
//     if player.x > ghost.x - 300 {
//         if player.x < ghost.x + 300 {
//             // Chase left and right:
//             if player.x > ghost.x {
//                 ghost.speedX = 1
//             } else {
//                 ghost.speedX = -1
//             }
//             // Chase up and down:
//             if player.y > ghost.y {
//                 ghost.speedY = 1
//             } else {
//                 ghost.speedY = -1
//             }
//         }
//     }
// }
//
// // ========== 🔥 FIREBALLS ==========
// // Runs 60 times a second for EACH 🔥. fireball is the fireball whose turn it is.
// func updateFireball(fireball: Fireball) {
//     if fireball.facingWall() {
//         fireball.remove()
//     }
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
// // Runs every frame you touch a 🍄. spring is that spring.
// func playerTouchedSpring(spring: Spring) {
//     player.speedY = 25
// }
//
// // Runs every frame you touch a ⭐. star is that star.
// func playerTouchedStar(star: Star) {
//     star.remove()
//     player.timer = 300
// }
//
// // Runs every frame you touch an enemy. enemy is that enemy.
// func playerTouchedEnemy(enemy: Enemy) {
//     if player.timer > 0 {
//         // Star power: plow right through.
//         enemy.remove()
//     } else if player.speedY < 0 {
//         // Falling onto it: squish it and bounce.
//         game.playSound(.stomp)
//         enemy.burst("💥")
//         game.shake()
//         enemy.remove()
//         player.speedY = 12
//     } else {
//         // Walked into it: ouch!
//         player.hurt()
//     }
// }
//
// // Runs every frame a 🔥 touches an enemy. fireball is that fireball; enemy is that enemy.
// func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {
//     enemy.remove()
//     fireball.remove()
// }
//
// // Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
// func playerGotHurt() {
//     game.showMessage("Ouch!")
//     game.deaths += 1
//     game.lives -= 1
//     if game.lives == 0 {
//         game.lose()
//     }
// }
//
// // Runs every frame you touch the 🚩.
// func playerTouchedFlag() {
//     if game.coinsLeft == 0 {
//         game.nextLevel()
//     } else {
//         game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
//     }
// }
//#-end-hidden-code
/*:
 # 23. Design Your Own Game
 This is the whole game you built: every page's finished code, in one place. Make it yours! There are no checks here: playtest it, and ask a friend to play.

 ## Your turn
 - Draw your own level in `game.level`, between the `"""` lines: one `P`, every row the same length, and the 🚩 in the last column.
 - Beat it yourself. Then add ideas from the list below.

 **Map letters:** `#` block, `=` brick, `.` air, `P` you, `F` 🚩, `o` 🪙, `^` 🌵, `s` 🍄, `*` ⭐, `c` 🦀, `b` 🐝, `g` 👻, `f` 🐸, `T` 🌳, `~` ☁️.

 **Level tips:** you can jump walls up to 2 blocks and pits up to 3 squares; a 🍄 clears 4 blocks. Bees need 3 empty squares above them. The 🚩 waits for every coin, and you have 3 lives.

 ## Ideas
 - 🐸 A frog that hops: write its `updateFrog`, with gravity, and a timer like the bee's that gives it a `speedY` of 14 every 90 frames.
 - ⏫ A double jump: a var at the top that counts the jumps you have left, `justPressed(.up)`, and a reset when you're on the ground.
 - 🦇 A bat that chases only when you're close: `game.ghostEmoji`; both speeds 0, unless `player.x` is more than `ghost.x - 300` and less than `ghost.x + 300`.
 - 🦀 Crabs that turn at ledges: `crab.facingLedge()`.
 - 👾 A ghost that drops crabs every 2 seconds: `ghost.timer` and `game.spawn`.
 - 💥 Stomp effects: the `.stomp` sound, the enemy's `burst`, the game's `shake`.
 - ⏳ A time limit: `game.timer` and the game's `lose()`.
 - 🏆 A high score that survives game over: a var at the top.
 - 🎨 New looks: `game.background`, `game.weather`, `game.crabEmoji`.
 - 🎮 Tune the feel: coyote time of 10 (change both 6s next to `framesInAir`), or a jump of 25 with a gravity of 2.
 - 3️⃣ A level 3: `game.level3`. Or just one level: an empty `game.level2`.
 - 🙈 A finished look: `game.showNumbers` hides the inspector.

 The README page lists every command.
 */

// 👉 THIS PAGE: your game. Change anything!

// ========== 🗺️ LEVELS ==========
// Level 1: your map. Each line is one row of squares.
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

// Level 2: the map you play after level 1's 🚩. Each line is one row of squares.
game.level2 = """
..............................
...~..........~...........~...
..............................
..............................
..............................
......o..ooo.......o..........
........#####.................
.P...#..............c...#.c..F
##############..##############
"""

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
// The game's start function. Runs once when the game starts, and again when it starts over
// (after game over, or when you play again after a win).
func startGame(game: Game) {
    game.lives = 3
}

// The game's update function. Runs 60 times a second, after every other function.
func updateGame(game: Game) {
    game.showText("⭐ " + String(game.score))
    // Stopwatch: count frames. 60 frames is 1 second.
    game.timer += 1
    game.showText("⏱ " + String(game.timer / 60))
    game.showText("💥 " + String(game.deaths))
    game.showText("❤️ " + String(game.lives))
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
    game.showMessage("Ouch!")
    game.deaths += 1
    game.lives -= 1
    if game.lives == 0 {
        game.lose()
    }
}

// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    if game.coinsLeft == 0 {
        game.nextLevel()
    } else {
        game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
    }
}
