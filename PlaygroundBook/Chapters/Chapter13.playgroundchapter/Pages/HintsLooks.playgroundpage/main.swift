/*:
 # Hints: Looks
 Find your page below. Read **Hint 1**, and try it before you read the next one. Still stuck after **Hint 3**? The next numbered page starts with your page's finished code.

 Finished this Part? Go to the next page: **15. Boing!**.

 ## 13. Hero Moves
 **Hint 1:** Ask about the ground first. In the air there's one look. On the ground there are two: walking and standing still.

 **Hint 2:** At the 👉 "How you look" comment, an if / else that asks `player.isOnGround()`. In the `else` part (in the air), set `player.emoji` to 🤸.

 **Hint 3:** In the ground part, a second if / else asks whether `player.speedX` is exactly 0, with `==`. Standing still: 🧍. Otherwise, walking: 🏃.

 **Good to know:**
 - How you look can depend on what you're doing. `updatePlayer` runs 60 times a second, so it can change `player.emoji` every frame, like a flip book.
 - The engine mirrors your emoji to face the way you move.
 - Your look code goes at the end of `updatePlayer`, so it decides the look after everything else.

 **Predict:** your look code sets `player.emoji` every frame. What happens to the 🙂 that `startPlayer` sets? *Answer:* you never see it: one frame later, your look code changes it.

 **Try it:** falling fast? At the very bottom of `updatePlayer`: `if player.speedY < -15 { player.emoji = "😱" }`.

 **Try it:** a flip-book run. Count frames in your own var at the top (like `framesInAir`), start the count over every 16 frames, and switch between 🏃 and 🚶 every 8 frames. (Why not `player.timer`? A later page, Star Power, needs it.)

 ## 14. Backgrounds
 **Hint 1:** Both steps are Settings: lines in ⚙️ SETTINGS, at the 👉 comments, outside every function. You don't change any function on Backgrounds.

 **Hint 2:** Step 1: set `game.horizonColor` to a color, written like the `game.skyColor` line above it. Step 2: copy the mountains' `game.addLayer` line and change it: your own emoji, a `y` of 64 (on the floor), a smaller `size`, and a smaller `distance` (closer things scroll faster).

 **Hint 3:** Step 1: a warm color, like `.hex("ffd194")`. Step 2: emoji like 🌲 and 🌳 with spaces between them, a `size` of about 100, and a `distance` of 2.

 **Good to know:**
 - Look out of a car window: the trees zoom by, and the mountains far away barely move. **Far things scroll slower.** So a game background is layers at different distances. That's called *parallax*.
 - **Settings** are code in the ⚙️ SETTINGS section, outside every function. They run once, before the game starts.
 - `game.skyColor` is the color at the top of the sky, and `game.horizonColor` is the color at the bottom. The sky fades from one to the other. A color is written like `.hex("ff8800")`, the way web pages write colors.
 - `game.addLayer(...)` adds a row of emoji behind the level. Each emoji is one spot `size` points wide, a space is a gap, and the row repeats forever. `y` is how high its bottom sits (64 stands on the floor). `distance` 1 scrolls with the level, 2 half as fast, and 10 barely moves.

 **Predict:** walk right. Which moves fastest: the level, your trees, or the mountains? *Answer:* the level, then your trees, then the mountains.

 **Try it:**
 - A ready-made scene: `game.background = .night`. There are 12: `.plain` `.day` `.sunset` `.night` `.forest` `.mountains` `.city` `.desert` `.snow` `.space` `.underwater` `.cave`. Lines after it can change it.
 - A moon far away (the spaces keep it from repeating): `game.addLayer("🌕               ", y: 400, size: 80, distance: 40)`.
 - Snow: `game.weather = "❄️"`. Or rain, leaves, anything: `"🍂🍁"`.
 - Brick blocks: `game.blockEmoji = "🧱"`.
 */
