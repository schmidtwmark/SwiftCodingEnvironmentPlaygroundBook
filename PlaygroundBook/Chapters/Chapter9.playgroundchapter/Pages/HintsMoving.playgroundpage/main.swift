/*:
 # Hints: Moving
 Find your page below. Read **Hint 1**, and try it before you read the next one. Still stuck after **Hint 3**? The next numbered page starts with your page's finished code.

 Finished this Part? Go to the next page: **5. Coins**.

 ## 1. Walk
 **Hint 1:** ▶ already works: while ▶ is held, your code sets `player.speedX`. ◀ needs its own part of the same `if`, and so does "no button".

 **Hint 2:** After the ▶ part, add an `else if` that asks `isPressed(.left)`, and then an `else`. Each part sets `player.speedX`.

 **Hint 3:** In the `else if`, a speed of minus 6: a negative speed walks left. In the `else`, a speed of 0: stand still. Check that every `{` has its own `}`.

 **Good to know:**
 - A video game is a flip book: the screen is redrawn 60 times a second, and each picture is a **frame**. You don't write that loop. The **game engine** calls your functions for you, so you never call them yourself.
 - `startPlayer` is a **start function**: it runs once, when the level starts. `updatePlayer` is an **update function**: it runs every frame. `playerTouchedFlag` is an **event function**: it runs when something happens, here every frame you touch the 🚩, and yours calls `game.win()`.
 - The engine **hands your function the player**. That's the `player: Player` in its first line: inside the function, `player` is you.
 - After your function runs, the engine moves you by `player.speedX`: a positive speed walks right, a negative one walks left, and 0 stands still. Moving things by their speeds, blocks and the camera are **engine rules**. Everything else the game does is code you can see.
 - The gray numbers above the game are the **inspector**: the engine's numbers, for you, the designer. Watch `speedX` there.
 - The line at the top of the code, `// 👉 THIS PAGE:`, says what's new, and a 👉 comment marks where your code goes. Your changes stay on their page: the next page starts with the book's finished code.
 - No `while` loops in these functions: the engine already calls update functions 60 times a second.
 - The last page, **README**, lists every command.

 **Predict:** ▶ works. What happens when you let go of ▶? *Answer:* you keep sliding! `speedX` stays 6 until your code changes it. That's why "no button" needs its own part.

 **Try it:** pick your own hero emoji in `startPlayer`. Then make yourself twice as fast, both ways. Predict first!

 ## 2. Fall
 **Hint 1:** Gravity changes your **speed** a little every frame, not your place.

 **Hint 2:** Go to the 👉 Gravity comment, at the bottom of `updatePlayer`, below the whole if / else if / else. Change `player.speedY` there with `-=`.

 **Hint 3:** One line that takes 1 away from `player.speedY`. Outside every `if`, it runs on every frame.

 **Good to know:**
 - Up and down works like sideways. `player.y` is how high you are: bigger `y` is higher up. `player.speedY` is how far you move up in one frame, and a negative speed moves you down.
 - When you land on a block, the engine sets `speedY` back to 0. That's an engine rule.
 - **Gravity** is a counter that runs 60 times a second: it takes a little away from your speed every frame, so you fall faster and faster, like a real ball.

 **Predict:** your gravity runs every frame. While you fall, what does `speedY` do in the inspector? *Answer:* it goes -1, -2, -3, ... a little more every frame, until you land and it's 0 again.

 **Try it:** Jupiter gravity pulls twice as hard. What does taking away 0 do?

 ## 3. Jump
 **Hint 1:** The jump line runs on every frame ▲ is held, even in mid-air. It should run only when you're also standing on a block.

 **Hint 2:** Inside the `if` that asks about ▲, put a second `if` that asks `player.isOnGround()`. The jump line goes inside that one.

 **Hint 3:** Two questions, one inside the other: is ▲ pressed? Then: am I on a block? Only then, `speedY` becomes 18. If Playgrounds adds a `}` for you, check that every `{` has its own `}`.

 **Good to know:**
 - A jump sets your speed **once**, to a big number going up. Gravity takes 1 away every frame, so you slow down, stop, and fall back.
 - `player.isOnGround()` is `true` while you stand on a block. It's a true-or-false question, like `robot.facingEmptySpace()` on the robot pages.
 - An `if` inside an `if`: the inside one is only asked when the outside one is `true`. For example, this would make you run fast, but only up high:
 ```
 if isPressed(.right) {
     if player.y > 400 {
         player.speedX = 12
     }
 }
 ```
 - Falling out of the level, or touching a 🌵, is an **ouch**. It's an engine rule: the engine sends you back to the start, makes you blink for a second, and calls your event function `playerGotHurt` once. Yours shows "Ouch!" with `game.showMessage`.

 **Predict:** what happens if you **hold** ▲ down? *Answer:* before your fix, you fly up and away. After it, you jump, land, and jump again.

 **Try it:** can a jump of 12 get over the 2-block wall? Predict first, then try it. Then try a jump of 25 with a gravity of 2. Changing numbers until a game feels right is called **tuning**.

 ## 4. Coyote Time
 **Hint 1:** Two jobs: first count, then use the count. `framesInAir` should say how many frames ago you last stood on a block: 0 on a block, then 1, 2, 3, ... in the air.

 **Hint 2:** At the 👉 coyote time comment, an if / else that asks `player.isOnGround()`. On a block, set `framesInAir` to 0. Otherwise, add 1 to it with `+=`. Then, in your jump, the inside `if` asks about `framesInAir` instead of `isOnGround()`.

 **Hint 3:** The jump's inside `if` asks: is `framesInAir` less than 6? When you jump, also set `framesInAir` to 6, so the same `if` stays false until you land. That's "using it up".

 **Good to know:**
 - **Why games do this.** Remember Wile E. Coyote, from the Road Runner cartoons? He runs off a cliff, keeps running on thin air for a moment, looks down, and only **then** falls. People press ▲ a little late: often 2 or 3 frames after their feet leave the block. "Only on the ground" makes them fall, and it feels unfair: "I pressed it!" So almost every platformer lets you jump for a few frames after you leave a ledge. Players never notice it. They just feel that the game is fair. Good game design is full of hidden help like this.
 - **A var that remembers.** A `var` inside a function starts over every time the function runs, so it can't remember anything. A `var` at the top of the page, **outside every function**, keeps its number from frame to frame. Your page has one: `framesInAir`, in the 🔢 VARIABLES section.
 - Here's the idea with a different counter. Don't type it: it's a sprint that kicks in after you hold ▶ for 1 second.
 ```
 var framesHeld = 0      // at the top, outside every function

 // in updatePlayer, after the walk:
 if isPressed(.right) {
     framesHeld += 1
 } else {
     framesHeld = 0
 }
 if framesHeld > 60 {
     player.speedX = 12
 }
 ```
 - 6 frames is a tenth of a second.
 - The inspector shows how your last jump happened, like `last jump: 3 frames after the ledge 🐺 (coyote time)`, or `from the ground, 4 frames before the edge` when you jumped early. Fall short? You jumped too early: wait for the very edge.

 **Feel it:** without your new code, try to jump the Canyon's first gap 5 times. How often do you fall in? Try again after your code.

 **Predict:** you jump, and you keep holding ▲. On the next frame you're in the air, but `framesInAir` is only 1. What happens? *Answer:* your jump's `if` is still true, so you jump again, and again: holding ▲ flies. That's why a jump uses up your coyote time.

 **Try it:** make coyote time 10 frames. What else has to change, so you still can't jump twice? (Hold ▲ to test it.)
 */
