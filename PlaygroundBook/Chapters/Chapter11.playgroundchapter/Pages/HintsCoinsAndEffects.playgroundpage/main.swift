/*:
 # Hints: Coins and Effects
 Find your page below. Read **Hint 1**, and try it before you read the next one. Still stuck after **Hint 3**? The next numbered page starts with your page's finished code.

 Finished this Part? Go to the next page: **9. Crab Patrol**.

 ## 5. Coins
 **Hint 1:** `playerTouchedCoin` runs on every frame you touch a coin. Make it count the coin, and then make sure that coin can't count again.

 **Hint 2:** In `playerTouchedCoin`, add 1 to `game.score` with `+=`. Then take the coin out of the game with its `remove()`. Inside this function, the coin you touched is called `coin`.

 **Hint 3:** Two lines: the score goes up by 1, then `coin` (not `player`!) is removed. Removing the player is an ouch.

 **Good to know:**
 - Some functions run when something **happens**. They're called **event functions**, and you've had two since the first pages: `playerTouchedFlag` and `playerGotHurt`. The engine hands this one **the coin you touched**.
 - `game.score` is a number that only your code changes. Watch it in the inspector.
 - On Coins the checklist keeps the 🚩 🔒 until every coin is gone.

 **Predict:** you stand on one coin for 1 second, and your code doesn't remove it. How many points do you get? *Answer:* about 60: `playerTouchedCoin` runs on every frame you touch it. That's why each coin has to disappear.

 **Try it:** hop a little whenever you grab a coin: give `player.speedY` a small number in `playerTouchedCoin`. (`player` works in every function, not just in `updatePlayer`.)

 ## 6. Show the Score
 **Hint 1:** Text you show lasts one frame, so the score has to be shown again on every frame: in `updateGame`, at the 👉 comment.

 **Hint 2:** Call `game.showText`, with the text in its parentheses. The text is two pieces joined with `+`: the text `"⭐ "`, and the score turned into text with `String()`.

 **Hint 3:** In the parentheses: the star text in quotes, then `+`, then `String` with `game.score` inside its own parentheses.

 **Good to know:**
 - The screen is redrawn **every frame**, so text that should stay on the screen has to be shown again every frame. `updateGame` is the game's own update function: it runs 60 times a second, **after** every other function, so it sees the frame's final numbers.
 - `game.score` is a number, but `game.showText` needs text. `String()` turns a number into text, and `+` joins two texts: `"Level " + String(3)` is `"Level 3"`.
 - **The rule:** when something **happens**, use `game.showMessage`, like your "Ouch!". When something should **stay** on the screen, use `game.showText` in `updateGame`.

 **Predict:** what would `game.showText("⭐ game.score")` show? And why not put `game.showText` in `playerTouchedCoin`? *Answer:* it shows the words "⭐ game.score": everything inside quotes is just text. And in `playerTouchedCoin`, the score would flash for one frame when you grab a coin, then disappear.

 **Try it:** make each coin worth 10. Then show a second line under the score, like the name of your world: every `game.showText` is one more line.

 ## 7. Sounds
 **Hint 1:** Find the two moments in your code: the event function that runs when you grab a coin, and the line where a jump starts.

 **Hint 2:** The coin moment is `playerTouchedCoin`, next to the line that removes the coin. The jump moment is right next to the line that sets `speedY` to 18, inside both of the jump's `if`s.

 **Hint 3:** In each place, one line: `game.playSound`, with the sound's name in its parentheses: `.coin` in one place, `.jump` in the other.

 **Good to know:**
 - An **event function** runs when something happens. An **update function** runs 60 times a second, so a sound in the wrong place plays 60 times a second and buzzes.
 - Sounds belong to the game. There are 12: `.coin` `.jump` `.hurt` `.stomp` `.powerUp` `.win` `.lose` `.laser` `.explosion` `.boing` `.blip` `.whoosh`. Keep the volume low, or use headphones.
 - Too loud, or too quiet? `game.soundVolume` goes from 0 (silent) to 100 (the loudest), and it starts at 30. Try a line like `game.soundVolume = 60` at the top of your code, outside every function.
 - The 🚩 is 🔒 until every coin is gone, so you hear them all.
 - No sound? Check the iPad's volume, Silent mode and `game.soundVolume`. The checks don't need the speaker: they listen to the engine.

 **Predict:** what would you hear if the jump sound were the first line of `updatePlayer`? *Answer:* a buzz: it would play on every frame, 60 times a second, even standing still.

 **Try it:** a `.boing` jump. Then a `.powerUp` sound when your score gets to 8 (an `if` in `playerTouchedCoin`).

 ## 8. Sparkles
 **Hint 1:** The same two moments as on Sounds: grabbing a coin, and the start of a jump. Each effect comes out of a thing: the coin, or you.

 **Hint 2:** In `playerTouchedCoin`, call `burst` on `coin`, with ✨. Next to your jump sound, call `burst` on `player`, with 💨, and give it a `count` and a `speed`.

 **Hint 3:** The coin's burst needs only the emoji, in quotes. Yours needs three things in its parentheses, with commas between them: "💨" in quotes, then `count:` 6, then `speed:` 2.

 **Good to know:**
 - `player.burst("⭐")` throws a burst of ⭐ out of the player, and they fade in half a second. You can also say how many (`count`, 1 to 50) and how far each one flies every frame (`speed`; 0 floats up).
 - **The rule:** an effect at a **place** belongs to the thing there (`coin.burst`, `player.burst`). An effect for the **whole screen**, or for the speaker, belongs to the game (`game.playSound`, `game.shake`).
 - The 🚩 is 🔒 until every coin is gone.

 **Predict:** you put the dust right above your gravity line instead. What would you see? *Answer:* a cloud of 💨 all the time: that line runs on every frame, not once per jump.

 **Try it:**
 - A bigger coin burst: 30 sparkles at speed 10.
 - A floating "+1": `coin.burst("+1", count: 1, speed: 0)`.
 - A trail, at the bottom of `updatePlayer`: `if player.speedX != 0 { player.burst("✨", count: 1, speed: 0) }`. (`!=` means "is not".)
 - Shake the screen when you grab a coin: `game.shake(strength: 10)`.
 */
