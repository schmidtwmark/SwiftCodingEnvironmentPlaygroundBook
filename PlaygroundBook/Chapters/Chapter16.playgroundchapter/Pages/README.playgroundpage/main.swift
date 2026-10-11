/*:
 # Game Design: the reference
 Everything the engine knows, on one page. Nothing here runs: copy what you need into a page.

 The book is **one game**, built one idea at a time. Stuck? Parts 1 to 6 each end with a **Hints** page: three hints for each of its pages. And every page starts with the finished code of the page before it, so the next page shows the answer. Go at your own pace. **Design Your Own Game** has all the code, and you can go there any time.

 ## The one rule
 Every frame (60 times a second), the engine moves every thing by its `speedX` and `speedY`. **Your functions change speeds.**
 - Blocks stop things. Ghosts float through them.
 - Landing on a block, or bumping your head, sets `speedY` to 0.
 - Bumping a wall sideways stops a thing but keeps its `speedX`, so a function can flip it.
 - Nothing falls unless its own update function adds gravity.

 Every number is a whole number. **60 frames is 1 second.**

 ## What the engine does by itself
 Only these rules. Everything else the game does is code you can see on the page.
 - Moving every thing by its speeds, blocks, and the camera that follows you.
 - An **ouch** when you touch a 🌵 or fall out of the level: you go back to the start and blink for a second, and the engine calls your `playerGotHurt` once.
 - On a few pages, the checklist locks the 🚩 (🔒) until every coin or crab is gone.
 - Drawing it all, and the checklist.
 */

/*:
 ## Functions: you write them, the engine calls them
 Never call them yourself, and never put `while` in one. The first line must be **exactly** this. If it isn't (a typo, a different name), the engine can't find your function and uses its built-in one, which **does nothing**. Then a line above the game says "⚠️ Can't find:" and the exact first line.

 | First line | When it runs |
 |---|---|
 | `func startPlayer(player: Player) {` | when the level starts, and after every ouch |
 | `func updatePlayer(player: Player) {` | 60 times a second |
 | `func startGame(game: Game) {` | when the game starts, and again when it starts over (after game over, or when you play again after a win) |
 | `func updateGame(game: Game) {` | 60 times a second, after everything else |
 | `func startCrab(crab: Crab) {` | for EACH 🦀 when the level starts, and after every ouch |
 | `func updateCrab(crab: Crab) {` | 60 times a second for EACH 🦀 |
 | `startBee(bee: Bee)`, `updateBee(bee: Bee)` | the same, for EACH 🐝 |
 | `startGhost(ghost: Ghost)`, `updateGhost(ghost: Ghost)` | the same, for EACH 👻 |
 | `startFrog(frog: Frog)`, `updateFrog(frog: Frog)` | the same, for EACH 🐸 |
 | `startFireball(fireball: Fireball)`, `updateFireball(fireball: Fireball)` | for EACH 🔥 that `game.spawn` makes |

 ## Event functions: the engine calls them when something happens
 The touch functions run **every frame** two things touch. Never call these yourself either.

 | First line | When it runs |
 |---|---|
 | `func playerTouchedCoin(coin: Coin) {` | every frame you touch a 🪙 |
 | `func playerTouchedEnemy(enemy: Enemy) {` | every frame you touch an enemy |
 | `func playerTouchedFlag() {` | every frame you touch the 🚩 |
 | `func playerTouchedSpring(spring: Spring) {` | every frame you touch a 🍄 |
 | `func playerTouchedStar(star: Star) {` | every frame you touch a ⭐ |
 | `func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {` | every frame a 🔥 touches an enemy |
 | `func playerGotHurt() {` | **once** for every ouch: an enemy, spikes, a fall or `player.hurt()` |

 Every built-in function does nothing. An enemy hurts you only because your `playerTouchedEnemy` calls `player.hurt()`, and the 🚩 wins only because your `playerTouchedFlag` calls `game.win()`.
 */

/*:
 ## Every thing
 `player`, and the `crab`, `bee`, `ghost`, `frog`, `coin`, `spring`, `star`, `fireball` your functions are handed:

 | | |
 |---|---|
 | `x`, `y` | where its middle is (bigger y is higher). Read them to compare places. |
 | `speedX`, `speedY` | how far the engine moves it every frame (positive is right / up) |
 | `emoji` | what it looks like. The engine mirrors it to face the way it moves. |
 | `timer` | its own frame counter: count with `timer += 1`, start over with `timer = 0`. Goes back to 0 after an ouch. |
 | `isOnGround()` | true while standing on a block |
 | `facingWall()` | true when a block or the edge of the level is right in front |
 | `facingLedge()` | true when the next step forward would walk off the edge |
 | `facingRight()` | true when it faces right |
 | `remove()` | takes it out of the game (on the player: the same as `player.hurt()`) |
 | `burst("✨", count: 8, speed: 4)` | emoji fly out from it and fade in half a second |
 | `player.hurt()` | ouch! You and every enemy go back to the start; spawned things disappear. |

 ## The game
 | | |
 |---|---|
 | `game.score`, `game.deaths`, `game.lives`, `game.timer` | your numbers: the engine never changes them. Game over puts them back. |
 | `game.coinsLeft`, `game.enemiesLeft`, `game.levelNumber` | read only |
 | `game.showText("Level " + String(game.levelNumber))` | text at the top right for ONE frame: call it from updateGame |
 | `game.showMessage("Hi!")` | a big message for 2 seconds |
 | `game.playSound(.blip)` | `.coin` `.jump` `.hurt` `.stomp` `.powerUp` `.win` `.lose` `.laser` `.explosion` `.boing` `.blip` `.whoosh` |
 | `game.soundVolume = 60` | how loud the sounds are: 0 (silent) to 100 (the loudest). It starts at 30. |
 | `game.shake(strength: 8)` | shakes the screen (1 to 40) |
 | `game.spawn(.coin, x: player.x, y: player.y + 200, speedX: 0, speedY: 0)` | makes a new `.coin` `.crab` `.bee` `.ghost` `.frog` `.fireball` `.spring` or `.star` |
 | `game.win()`, `game.lose()`, `game.nextLevel()` | win, game over, or the next level (after the last level, it wins) |

 ## Buttons
 **Controls:** tap the game once, then use the arrow keys ← → ↑ ↓, or hold the ◀ ▶ ▲ ▼ buttons under the game.

 In code, the buttons are `.left` `.right` `.up` `.down`. ▼ shows up once your code asks about it.
 - `isPressed(.right)` is true every frame the button is held.
 - `justPressed(.up)` is true only on the first frame of a press.

 ## The inspector
 The gray numbers above the game: your `x`, `y`, `speedX`, `speedY` and `isOnGround()`, then the numbers the page is about. On Coyote Time it says how your last jump happened: from the ground (and how many frames before the edge), some frames after the ledge (coyote time), or in mid-air.
 */

/*:
 ## Settings (at the top of a page, outside every function)
 ```
 game.level = """
 ..........
 .P......F.
 ##########
 """
 game.level2 = ""                      // more maps for game.nextLevel()
 game.background = .sunset             // a ready-made scene
 game.skyColor = .hex("1a1a40")        // the top of the sky
 game.horizonColor = .hex("ff9e6b")    // the bottom of the sky
 game.addLayer("🏢  🏬 ", y: 64, size: 160, distance: 3)
 game.weather = "❄️"
 game.blockColor = .brown
 game.blockEmoji = "🧱"
 game.crabEmoji = "🦞"                 // also coinEmoji, beeEmoji, ghostEmoji, frogEmoji,
                                       // spikeEmoji, flagEmoji, springEmoji, starEmoji, fireballEmoji
 game.showNumbers = false              // hides the inspector
 ```
 A function can change the sky, layers and weather while the game runs too; game over puts them back. Blocks get their color and emoji when a level starts.

 Backgrounds: `.plain` `.day` `.sunset` `.night` `.forest` `.mountains` `.city` `.desert` `.snow` `.space` `.underwater` `.cave`.

 Colors: `.hex("ff8800")`, `.rgb(255, 136, 0)`, or `.black` `.white` `.red` `.orange` `.yellow` `.green` `.blue` `.purple` `.pink` `.brown` `.gray`.

 ## Counting frames
 A thing's own timer: a ghost that drops a coin every 3 seconds.
 ```
 ghost.timer += 1                       // count frames: 60 frames is 1 second
 if ghost.timer == 180 {                // after 3 seconds...
     game.spawn(.coin, x: ghost.x, y: ghost.y)
     ghost.timer = 0                    // ...start over
 }
 ```
 A `var` at the top of the page, outside every function, keeps its number from frame to frame, and the engine never resets it. Use one for a count that isn't a thing's (like coyote time), a best time, or a high score:
 ```
 var framesHeld = 0       // at the top

 // in an update function:
 if isPressed(.right) {
     framesHeld += 1
 } else {
     framesHeld = 0
 }
 ```
 Frames divided by 60 are whole seconds: dividing whole numbers drops the leftover, so `90 / 60` is 1.

 ## Game feel
 **Coyote time:** you can still jump for a few frames after you run off a ledge. Players never see it. They just feel that the game is fair.

 ## Numbers in text
 `String(game.levelNumber)` turns a number into text, and `+` joins texts: `"Level " + String(game.levelNumber)`.
 */

/*:
 ## Map letters
 | | | | |
 |---|---|---|---|
 | `#` block | `=` brick | `.` air | `P` you |
 | `F` 🚩 | `o` 🪙 coin | `^` 🌵 spikes | `s` 🍄 spring |
 | `*` ⭐ star | `c` 🦀 crab | `b` 🐝 bee | `g` 👻 ghost |
 | `f` 🐸 frog | `T` 🌳 tree | `~` ☁️ cloud | |

 **Level tips:** walls up to 2 blocks can be jumped, and a 🍄 clears 4. Pits up to 3 squares wide; a 4-wide pit needs the very edge. Bees need 3 empty squares above them. A ⭐ lasts about 28 squares of running. 9 rows fill the screen.

 ## Stuck?
 1. Find the first ❌ in the checklist above the game.
 2. Open the **Hints** page at the end of the Part, and read one hint at a time.
 3. Look at the next page: it starts with this page's finished code.
 4. Nothing happens, or "⚠️ Can't find:"? The `func` line must be exactly the one in the tables above.
 5. Frozen? There's a `while` in one of your functions: use `if`.
 6. "Game numbers are whole numbers", or "cannot assign value of type 'Double' to type 'Int'"? Use 2, not 2.5.
 7. The arrow keys don't work? Tap the game once.
 8. No sound? Check the iPad's volume, Silent mode and `game.soundVolume`.
 9. An error you can't find? Don't give a variable a function's name, like `playerGotHurt` or `playerTouchedFlag`.
 10. Your level looks wrong? A map needs one `P` and one `F`, and a letter that isn't in the Map letters table becomes air.
 */
