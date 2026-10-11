/*:
 # Hints: Rules of the Game
 Find your page below. Read **Hint 1**, and try it before you read the next one. Still stuck after **Hint 3**? The next numbered page starts with your page's finished code.

 Finished this Part? Go to the next page: **23. Design Your Own Game**.

 ## 18. Stopwatch
 **Hint 1:** Two jobs in `updateGame`: count, then show. The count is in frames, but the screen should show seconds.

 **Hint 2:** At the 👉 Stopwatch comment, add 1 to `game.timer` with `+=`. Below it, a `game.showText` line like your ⭐ line, with ⏱ in front.

 **Hint 3:** The seconds are `game.timer` divided by 60. Put that inside `String()`, and join it to the "⏱ " text with `+`.

 **Good to know:**
 - `game.timer` is the game's own frame counter. Like every timer, it starts at 0 and changes only when your code changes it. Unlike a thing's timer, an ouch doesn't reset it: only game over does.
 - **60 frames is 1 second**, so the seconds are the frames divided by 60. Dividing whole numbers drops the leftover: `90 / 60` is 1.

 **Predict:** after 150 frames, how many whole seconds should your stopwatch show? *Answer:* 2. 150 frames is 2 seconds and 30 frames, and the leftover 30 is dropped.

 **Try it:** show your time when you win: right above `game.win()`, show a message with your whole seconds, like "🏁 12 seconds!".

 ## 19. Death Counter
 **Hint 1:** `playerGotHurt` runs once for every ouch: that's where to count. `updateGame` runs every frame: that's where to show the count.

 **Hint 2:** In `playerGotHurt`, add 1 to `game.deaths` with `+=`. In `updateGame`, one more `game.showText` line, like your ⭐ line.

 **Hint 3:** Copy your ⭐ line in `updateGame`. In the copy, change ⭐ to 💥, and `game.score` to `game.deaths`.

 **Good to know:**
 - `playerTouchedEnemy` runs every frame you touch an enemy. `playerGotHurt` is different: it runs **once for every ouch**, of any kind: an enemy, spikes, a fall, or `player.hurt()`.
 - Every ouch sends you back to the start, so games call it a death, and keep count.
 - Your 💥 count is real playtest data: how many did the Danger Zone take?

 **Predict:** you touch a 🌵. Which runs: `playerTouchedEnemy`, `playerGotHurt`, or both? *Answer:* only `playerGotHurt`. A 🌵 isn't an enemy, but it's an ouch. That's why the count goes in `playerGotHurt`.

 **Try it:** in `playerGotHurt`:
 - Show the count in your "Ouch!" message too, like "Ouch! 💥 3".
 - Shake the screen: `game.shake(strength: 12)`.
 - Play a sound: `game.playSound(.hurt)`.

 ## 20. Lives and Game Over
 **Hint 1:** Three places: `startGame` sets the lives once, `playerGotHurt` loses one on every ouch, and `updateGame` shows them.

 **Hint 2:** In `startGame`, set `game.lives` to 3. In `playerGotHurt`, take 1 away with `-=`, then an `if` that asks whether `game.lives` is exactly 0, with `==`. In `updateGame`, a ❤️ line like your 💥 line.

 **Hint 3:** Inside the `if`: the game's `lose()`. For the ❤️ line, copy your 💥 line, and change 💥 to ❤️ and `game.deaths` to `game.lives`.

 **Good to know:**
 - The game has its own start function: `startGame`. `startPlayer` runs after every ouch, but `startGame` runs only when the game starts, and again when it starts over after game over. That's where lives belong.
 - The game's `lose()` ends the game: "Game over", and then everything starts over from the beginning.
 - Run the Gauntlet to the 🚩 before your ❤️ run out.

 **Predict:** what if the lives were set in `startPlayer` instead? *Answer:* you could never lose. Every ouch takes a life, and then `startPlayer` puts the lives back to 3.

 **Try it:**
 - Hard mode: start with 1 life.
 - Your score under "Game over": right above your lose line, add `game.showMessage("⭐ " + String(game.score))`.
 - A row of hearts, in place of your ❤️ line. (The `if` matters: with 0 lives, `1...0` would stop the game.)

 ```
 var hearts = ""
 if game.lives > 0 {
     for _ in 1...game.lives {
         hearts = hearts + "❤️"
     }
 }
 game.showText(hearts)
 ```

 ## 21. Locked Flag
 **Hint 1:** Your 🚩 event function decides what touching the flag means. Before it wins, it should ask a question: is every coin collected?

 **Hint 2:** In `playerTouchedFlag`, put an if / else around the win. The `if` asks whether `game.coinsLeft` is exactly 0, with `==`. The `else` shows a message with `game.showMessage`.

 **Hint 3:** The message is three pieces joined with `+`: the text "🪙 ", then `String()` with `game.coinsLeft` inside it, then the text " coins left!".

 **Good to know:**
 - Remember the 🔒 on Coins? The checklist locked that flag. Now **you** build the lock.
 - `game.coinsLeft` is how many 🪙 are still in the level.
 - Some coins are behind you!

 **Predict:** your `playerTouchedFlag` runs every frame you stand on the 🚩. What happens to your message while you stand there? *Answer:* it's shown again on every frame, so it stays up the whole time you stand there.

 **Try it:**
 - Show the coins left in the corner every frame, in `updateGame`.
 - Squish every enemy first, too: `game.enemiesLeft`, and an `if` inside your `if`. (This level has no enemies: try it on Design Your Own Game.)
 - Show your score when you win: `game.showMessage("⭐ " + String(game.score))`, right above the win.

 ## 22. Level 2
 **Hint 1:** Two jobs: change the map (it's just text), and change what the 🚩 does once every coin is collected.

 **Hint 2:** In 🗺️ LEVELS, change letters between `game.level2`'s `"""` lines: swap some `.` for `o`, `c` or `#`. Then, in `playerTouchedFlag`, find the line that wins: that's the one to change.

 **Hint 3:** Replace the game's `win()` with the game's `nextLevel()`. Leave the `else` and its coins message as they are: your lock works on every level.

 **Good to know:**
 - A game can have more than one level, and your 🚩 event function decides what finishing a level means.
 - Each line of a map is one row of squares, top to bottom: `#` is a block, `.` is air, `P` is you, `F` is the 🚩, `o` is a 🪙 and `c` is a 🦀. Every letter is on the README page. The Level 2 page's own map is level 1.
 - Keep one `P` and one `F`, and keep every row the same length. Your 🚩 is 🔒 until every coin is collected, so put coins where you can reach them.
 - `nextLevel()` goes to the next level that has a map. Your score and the other game numbers carry over. After the last level, `nextLevel()` wins.
 - The checklist says which level you're on, and so does `game.levelNumber` in the inspector.

 **Predict:** you add a coin to level 2, behind where you start. What happens when you reach its 🚩 without it? *Answer:* your coins message: the lock from Locked Flag works on level 2 too. Go back for the coin.

 **Try it:**
 - A level 3: `game.level3 = """`, a map, and `"""`, under level 2.
 - Night on level 2: in `startPlayer`, add `if game.levelNumber == 2 { game.skyColor = .hex("0b1033") }`.
 - Show the level in `updateGame`: `game.showText("Level " + String(game.levelNumber))`.
 */
