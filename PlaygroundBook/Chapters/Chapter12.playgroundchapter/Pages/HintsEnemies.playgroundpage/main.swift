/*:
 # Hints: Enemies
 Find your page below. Read **Hint 1**, and try it before you read the next one. Still stuck after **Hint 3**? The next numbered page starts with your page's finished code.

 Finished this Part? Go to the next page: **13. Hero Moves**.

 ## 9. Crab Patrol
 **Hint 1:** Two functions, two jobs. `startCrab` gives each crab its first speed, once. `updateCrab` asks every frame whether it's time to turn around.

 **Hint 2:** At Step 1, in `startCrab`, set `crab.speedX` to a small negative number: slower than your 6. At Step 2, in `updateCrab`, an `if` that asks `crab.facingWall()`.

 **Hint 3:** Inside that `if`, `crab.speedX` gets minus itself: a minus sign in front of `crab.speedX` turns 2 into -2, and -2 into 2.

 **Good to know:**
 - This level has **three** crabs, but only **one** `updateCrab` function. Every frame, the engine calls it once for **each** crab. Inside the function, `crab` means **the crab whose turn it is**. Write the function once, and every crab follows it.
 - `crab: Crab` is a **parameter**: the name your function uses for the thing the engine hands it. The small `crab` is the name, and the capital `Crab` is what kind of thing it is. You've used parameters since Walk: `player: Player` and `coin: Coin`.
 - Crabs follow the same rule as you: every thing moves by its `speedX` and `speedY`, and functions change speeds. `startCrab` runs once for each crab when the level starts, and again after every ouch.
 - A wall stops a crab, but doesn't change its `speedX`, so your function can flip it. A minus sign in front of a number flips it: if `n` is 5, then `-n` is -5.
 - **Enemies hurt because your code says so.** Look at `playerTouchedEnemy` in ⚡ EVENTS: it runs every frame you touch an enemy, and it calls `player.hurt()`. That line is the only reason a crab hurts you. Try it: delete it, run, and walk into a crab. Then put it back!

 **Predict:** after Step 1, what will a crab do when it reaches a post? *Answer:* it stops and keeps pushing against the post: the wall stops it, but its speed stays the same. That's what Step 2 fixes.

 **Try it:** `crab.facingLedge()` is `true` when the crab's next step would walk off the edge of a platform. What could a crab do with it?

 ## 10. Busy Bees
 **Hint 1:** The bee's count already goes up 1 every frame. Its number tells you which second the bee is in: the up second (under 60) or the down second.

 **Hint 2:** At Step 1, an if / else that asks whether `bee.timer` is less than 60. Yes: `bee.speedY` is 2. Otherwise: -2. At Step 2, an `if` that asks whether `bee.timer` is exactly 120, with `==`.

 **Hint 3:** Inside Step 2's `if`, set `bee.timer` back to 0. Then the pattern starts over: 60 frames up, 60 frames down, forever.

 **Good to know:**
 - On Coyote Time, one var at the top counted for the one player. This level has three bees, and every bee needs its own count. So every thing has its own `timer`: a whole number that starts at 0 and changes only when your code changes it. It goes back to 0 after an ouch.
 - **60 frames is 1 second.** Watch `bee.timer` in the inspector.
 - Bees have no gravity, so they float. Down is a negative speed, like falling.
 - Up for exactly 60 frames and down for exactly 60 frames, so a bee always comes back to the same place.
 - **Playing tip:** when a bee flies up, its tunnel stays open for more than a second. Go as soon as a bee starts flying up: if you wait for the top, it's already coming back down.

 **Predict:** with only Step 1, where will the bees be after 5 seconds? *Answer:* at the bottom. After the first second, `bee.timer` is never under 60 again, so they fly down and stay down.

 **Try it:** make the bees fly a slanted path: a little to the right while they go up, and a little to the left while they go down. Predict the path first!

 ## 11. Ghost Chase
 **Hint 1:** The goal: the ghost chases your position. Every frame, it moves toward where you are, so it catches you if you stand still. The left-and-right half already moves it toward your `x`: it compares the `x`s and sets `ghost.speedX`. Yours moves it toward your `y` the same way: compare the `y`s and set `ghost.speedY`.

 **Hint 2:** At the 👉 comment, an if / else that asks whether `player.y` is more than `ghost.y`: you're higher than the ghost.

 **Hint 3:** Higher: the ghost's `speedY` is 1, up. Otherwise: -1, down. The same speeds as the left-and-right half.

 **Good to know:**
 - A function can look at **other** things too. Inside `updateGhost`, `ghost` is the ghost whose turn it is, and `player` is still you: `player` works in every function.
 - Same rule as everything: set the ghost's speeds, and the engine moves it.
 - The left-and-right half: if you're to the right of the ghost, the ghost's `x` is smaller than yours, so it moves right. Otherwise it moves left.
 - Ghosts float right through blocks! The 🌵 hurts too, so jump over it.
 - **Playing tip:** don't stop to read with the game running: the ghost reaches you in a few seconds.

 **Predict:** with only the left-and-right half, what does the ghost do when you jump? *Answer:* nothing: it stays at its own height. It can only follow you sideways.

 **Try it:** give it a new look with `ghost.emoji`. Then make it 😈 while it moves left and 👻 while it moves right.

 ## 12. Stomp
 **Hint 1:** When you land on top of an enemy, you're falling. When you walk into one, you're not. Your `speedY` tells which.

 **Hint 2:** In `playerTouchedEnemy`, put an if / else around the `player.hurt()` line. The `if` asks whether `player.speedY` is less than 0: falling. The `player.hurt()` line goes in the `else`.

 **Hint 3:** In the falling part, two lines: the `enemy` is taken out of the game with its `remove()`, and `player.speedY` becomes about 12, for a bounce.

 **Good to know:**
 - Enemies hurt you only because your `playerTouchedEnemy` calls `player.hurt()`. It's your code, so you can change the rules!
 - The engine hands this function the enemy you touched, so `enemy` can be a crab, a bee, a ghost or a frog.
 - A bounce is a jump you didn't press ▲ for.
 - On Stomp the checklist keeps the 🚩 🔒 until every crab is squished.

 **Predict:** jump, and watch `speedY` in the inspector on the way down. Is it positive or negative while you fall? And when you walk into a crab? *Answer:* negative while you fall. When you walk into a crab on the ground, it's 0.

 **Try it:** celebrate every stomp with `game.showMessage("Boing!")`, and add 1 to `game.score`.
 */
