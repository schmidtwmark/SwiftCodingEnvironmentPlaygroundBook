/*:
 # Hints: Power-ups
 Find your page below. Read **Hint 1**, and try it before you read the next one. Still stuck after **Hint 3**? The next numbered page starts with your page's finished code.

 Finished this Part? Go to the next page: **18. Stopwatch**.

 ## 15. Boing!
 **Hint 1:** A 🍄 works like a jump: it sets your `speedY` once, to a big number going up. It just needs a bigger number than your jump.

 **Hint 2:** In `playerTouchedSpring`, set `player.speedY` with `=`. 18 rises 171 points, and the wall is 256 points tall, so 18 isn't enough.

 **Hint 3:** A bigger speed rises much higher than you'd think: 20 rises 210 points, 22 rises 253, and 24 rises 300. Pick a number in the mid-20s, run, and see if you clear the wall.

 **Good to know:**
 - An event function can launch you. A 🍄 sets your speed once, and gravity does the rest, just like a jump. In a map, `s` is a 🍄.
 - `player` works in every function, not just in `updatePlayer`.
 - **Playing tip:** walk ▶ into the 🍄 and keep holding ▶. Leave ▲ alone while you bounce: just after you leave the ground, ▲ still jumps (that's your coyote time), and a jump of 18 replaces the 🍄's bigger bounce.
 - The second 🍄 takes you up to a coin shelf.

 **Predict:** a speed of 18 rises 171 points. Will 20 be enough? *Answer:* no: 20 rises only 210 points. Trying numbers until it feels right is **tuning**.

 **Try it:**
 - A new look: `spring.emoji = "🌀"`.
 - A super spring of 40.
 - A sound: `game.playSound(.boing)`.

 ## 16. Star Power
 **Hint 1:** One countdown, three places: the ⭐ starts it, `updatePlayer` counts it down, and `playerTouchedEnemy` asks whether it's still running.

 **Hint 2:** In `playerTouchedStar`, take the `star` out of the game with its `remove()`, and set `player.timer` to 5 seconds of frames. At the 👉 star power comment in `updatePlayer`, an `if` that asks whether `player.timer` is more than 0.

 **Hint 3:** 5 seconds is 300 frames. Inside the countdown's `if`: take 1 away from `player.timer`, and set `player.emoji` to 🤩. In `playerTouchedEnemy`, the new first branch asks the same question (is `player.timer` more than 0?) and only removes the `enemy`. The old `if` becomes an `else if`.

 **Good to know:**
 - You have star power whenever `player.timer` is above 0.
 - Why `player.timer`, and not a new var at the top? Every thing has its own timer, and this one belongs to the player. Nothing else in your code uses it.
 - Use `if`, not `while`: `updatePlayer` already runs every frame. Your countdown comes after the "How you look" part, so 🤩 wins while the star lasts.
 - In an if / else if / else, the **first** true branch wins. That's why star power goes first.
 - In a map, `*` is a ⭐. The only way through this mountain is a tunnel full of bees. Missed the ⭐? Run the page again.

 **Predict:** you grab the ⭐ and stand still for 2 seconds. What does `player.timer` say in the inspector? *Answer:* 180: it started at 300, and 2 seconds took away 120.

 **Try it:**
 - Speed boots: inside your countdown's `if`, add `player.speedX = player.speedX * 2`.
 - A longer star: 10 seconds.
 - Sparkles when you grab it: `star.burst("✨")`.

 ## 17. Fireballs
 **Hint 1:** Two questions: is ▼ **just** pressed? Then: which way do you face? Each way spawns a 🔥 with its own `speedX`.

 **Hint 2:** At the 👉 comment at the end of `updatePlayer`, an `if` that asks `justPressed(.down)`, with an if / else inside that asks `player.facingRight()`. In `fireballTouchedEnemy`, call `remove()` on the `enemy`, and on the `fireball`.

 **Hint 3:** Facing right: `game.spawn` a `.fireball` with `x:` your `player.x`, `y:` your `player.y`, `speedX:` 12 and `speedY:` 0. Facing left: the same, but with a `speedX:` of -12.

 **Good to know:**
 - `game.spawn` makes a brand-new thing while the game runs. (In Unity, that's called *Instantiate*.) For example, `game.spawn(.coin, x: player.x, y: player.y + 200)` makes a 🪙 above your head.
 - A spawned 🔥 follows the same rules as everything else: the engine moves it by its speeds, and blocks stop it. Its update function, `updateFireball`, is already written: a 🔥 disappears when it hits a wall.
 - `justPressed(.down)` is true only on the first frame of a press. `isPressed` is true every frame you hold it.
 - ▼ shows up next to ▲ once your code asks about it. With a keyboard, it's the ↓ key.
 - The frogs in this tunnel can't hop, and you can't jump over them. Time to throw some fire.

 **Predict:** what would happen with `isPressed(.down)` instead, if you held ▼? *Answer:* a new 🔥 on every frame: a stream of 60 fireballs a second.

 **Try it:**
 - Bouncing fireballs: in `updateFireball`, add gravity, and when a 🔥 is on the ground, give it a `speedY` of 8.
 - Knocked-out enemies drop a coin: `game.spawn(.coin, x: enemy.x, y: enemy.y + 64)` in `fireballTouchedEnemy`.
 - A `.laser` sound when you throw.
 */
