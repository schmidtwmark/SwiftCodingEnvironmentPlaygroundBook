# Game Design book: tests

The Game Design book (v7) is one chain of 23 pages in seven chapters, one per feature, plus the
`GameAPI` engine in `GameModules/GameAPI.playgroundmodule`. Each Part with code ends with a
prose-only Hints page (no code, no poster, like README):

| Chapter | Part | Pages |
|---|---|---|
| `Chapter9` | Part 1: Moving | 1. Walk, 2. Fall, 3. Jump, 4. Coyote Time, Hints: Moving |
| `Chapter11` | Part 2: Coins and Effects | 5. Coins, 6. Show the Score, 7. Sounds, 8. Sparkles, Hints: Coins and Effects |
| `Chapter12` | Part 3: Enemies | 9. Crab Patrol, 10. Busy Bees, 11. Ghost Chase, 12. Stomp, Hints: Enemies |
| `Chapter13` | Part 4: Looks | 13. Hero Moves, 14. Backgrounds, Hints: Looks |
| `Chapter14` | Part 5: Power-ups | 15. Boing!, 16. Star Power, 17. Fireballs, Hints: Power-ups |
| `Chapter15` | Part 6: Rules of the Game | 18. Stopwatch, 19. Death Counter, 20. Lives and Game Over, 21. Locked Flag, 22. Level 2, Hints: Rules of the Game |
| `Chapter16` | Part 7: Your Game | 23. Design Your Own Game, README (no code) |

There is no `Chapter10`: v7 moved its one page, Coyote Time, into Part 1 (its hints are now the last
section of Hints: Moving), and the later chapter folders kept their names.

v6 removed v5's Jump Buffer and Short Hop pages (from Coins on, the jump is Coyote Time's again, so
a quick tap is a full jump), and the hints from the goals above the game (see below). v6 also
calls what students write **functions**, never "scripts": start functions, update functions and
event functions, which the engine calls for you (students never call them). That covers every
page's code comments and prose, the Hints and README pages, the engine's strings and doc comments,
and the engine's own names (`Functions`, `FunctionName`, `functionWarning`, ...).

**One chain.** Every page's starter is the previous page's finished code plus this page's stub, so
the next page always shows the answer, and every page carries all the code of the pages before it.
Nothing is hidden: every behavior the game has (winning at the 🚩, an enemy hurting you, "Ouch!")
comes from code on the page. Students work through the book at their own pace; there are no
optional pages, but Hero Moves and Backgrounds say "You can skip this page" (nothing later needs them).

**The chain has one source:** `GameModules/Tools/chain.py`. It holds every page's banner, its stub
(what the starter adds to the previous page's finished code) and its answer (what the page's finished
code adds to its starter), and builds all 23 starters and solutions from them. `chain.py check`
confirms that every page's hidden code, solution block and starter are exactly the chain's, that
every stub only inserts lines, and that every page's prose (except Design Your Own Game) ends with
its Stuck line, `chain.stuck_line`: "Stuck? Open **Hints: Moving**. Still stuck? The next page has
the finished code." (the last page of a Part names the next code page, since its Hints page comes
in between). `run-tests.sh` and `check-book.sh` run it. `chain.py sync` rewrites every page's code
from the chain and keeps its prose. `chain.PARTS` names each Part and its Hints page folder.

Each page's prose card is short (about 60-90 words; page 1 and Design Your Own Game are longer):
the idea in a sentence or two, **Your turn** (1-3 goals), **Your tools**, and the Stuck line. The
Part's Hints page has, for each of its pages, **Hint 1** (a nudge), **Hint 2** (which tool, where, and
what it should do), **Hint 3** (nearly the answer, in words), then the background, the **Predict**
question with its answer, and the **Try it** ideas. Neither ever shows a line of an answer (the
prose check below enforces it). The code
starts with a banner, `// 👉 THIS PAGE: ...`, then fixed sections whose headers appear the first time
they have code: 🗺️ LEVELS, ⚙️ SETTINGS, 🔢 VARIABLES, 🙂 PLAYER, 🎮 GAME, 🦀 ENEMIES, 🔥 FIREBALLS,
⚡ EVENTS.

The engine lives outside `PlaygroundBook/Modules`, so the Robot, Text, Turtle and Bug Hunt books never
ship or compile it, and no other book's manifest may list these chapters. `inject_solutions.sh`
step 4 builds "Game Design.playgroundbook" and "Game Design Answer Key.playgroundbook" when the
**RobotPlaygroundBook** scheme builds.

## The engine's files

| File | What it holds |
|---|---|
| `Model.swift` | things, the 21 functions and their do-nothing built-in versions, `FunctionName`, `GameWiring`, `GameKey` (◀ ▶ ▲ ▼), `isPressed` / `justPressed` |
| `Game.swift` | `game`: its numbers, calls and Settings (sky, horizon, the 12 background presets, layers, weather, `level2`/`level3`), `spawn`, `nextLevel`, `playSound`, `soundVolume` (0 to 100, 30 at first; a Setting, so the checks and game over put the page's own back), `shake`, `GameColor`, `GameSound`, `ThingKind`, the friendly compile errors |
| `World.swift` | the map, one step (functions, physics, touches, playerGotHurt, updateGame), the jump log, `game.spawn`, `TestDrive` (with its effect log and the cool-down) |
| `Runtime.swift` | begin, tick, restart, freeze, next level, the effect queue, the checklist rows, the "Can't find:" lines, the status line and the inspector text (the header shows them) |
| `Effects.swift` | `Effect` (sound, burst, shake), `thing.burst`, and the models the iPad draws: particles, weather, the shake |
| `Synth.swift` | the 12 sounds made from math, and the 8-voice mixer the audio thread runs (no AVFoundation) |
| `Pages.swift` | the page table (`GamePage`, `PageInfo`: title, level, checks, lock, functions, inspector) and every page's level |
| `ChecksCore.swift` | the checks of Moving (Walk, Fall, Jump), Coins, Show the Score and Enemies (Crab Patrol, Busy Bees, Ghost Chase, Stomp) |
| `ChecksAffordances.swift` | the checks of Coyote Time |
| `ChecksExtras.swift` | the checks of Sounds, Sparkles, Looks, Power-ups and Rules of the Game |
| `Engine.swift` | iPad only: the live view, a UIKit goal header (title, status, checklist, "Can't find:" lines, inspector; no hints) above the SpriteKit game (sky gradient, layers, weather, particles, shake, the student's `showText` lines on a soft box, and messages), the ◀ ▶ ▲ ▼ buttons in their own strip below it (smaller in a short live view, never over the game; a tall live view centers it all), the "Tap the game" hint (between or under the buttons, or in the header), input, `GameLauncher` |
| `Audio.swift` | iPad only: one `AVAudioEngine` with one `AVAudioSourceNode` that pulls the mixer; `.ambient`; the main mixer's volume is 0.5 x `game.soundVolume` / 100, set at build and on every game step (`applyVolume`); gives up silently after 3 failed starts; `GameAudio.audioEnabled` is the kill switch |

Every tool builds every file except the iPad-only ones (`Engine.swift`, `Audio.swift`) with a glob,
so a new engine file needs no changes to the test tools. Sounds, bursts and shakes never play on the Mac: the
checks read each test drive's effect log (so a muted iPad passes the same checks), and the harness
counts what the bot's game asked for (`RESULT effects=`). Swift Playgrounds on the iPad compiles
against a different SDK than Xcode: keep to plain APIs (`inject_solutions.sh` step 4 refuses
`UnsafeMutableAudioBufferListPointer` and `noErr`, which failed on a real iPad).

## How a page hands its functions to the engine

Every page's hidden code is the same block (only `.crab` changes from page to page):

```swift
//#-hidden-code
import GameAPI
func _startGamePage() {
    let wire = GameWiring(.crab)
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
// ...the commented solution...
//#-end-hidden-code
```

The `GamePage` cases are `walk, fall, jump, coyote, coins, score, sounds, sparkles, crab, bee, ghost,
stomp, heroMoves, backgrounds, boing, starPower, fireballs, stopwatch, deathCounter, lives,
lockedFlag, level2, design`.

- GameAPI has a built-in version of all 21 functions, and **every built-in does nothing** (it only
  records that it ran). A page function with exactly the same first line replaces the built-in one.
  Only the engine's rules are built in: moving every thing by its speeds, blocks, the camera, an
  ouch for 🌵 or for falling out of the level, the blink after an ouch, the page locks (🔒 coins on
  Coins, Sounds and Sparkles; 🔒 crabs on Stomp), and drawing.
- A missing function, or one whose first line is different (a misspelled name or label, the v2
  `deltaTime: Double`, `crab: Enemy`), still compiles and quietly uses the built-in one. The header
  above the game then names it, right away, as `⚠️ Can't find: func updateCrab(crab: Crab)` (at most
  2 lines): any function from `PageInfo.functions` (every function the page's starter has) that the real
  game ran as its built-in, or that a check found missing (its result names the exact first line).
  A misspelled `playerTouchedFlag` would otherwise just make the 🚩 do nothing.

### The goals above the game (v6: no hints)

The header shows the page title, the checklist rows (✅ / ❌ / ⬜️ and each check's short name, the
first ❌ in bold), the "Can't find:" lines, a short status ("✅ Page complete! Go to the next page."
or, at the 🚩 with a ❌, "Almost! Fix the ❌ first."; on a locked 🚩 "Collect every coin first" or
"Squish every crab first"), and the gray inspector. Nothing else: no hint under the ❌, no map
problems, no "⏱ Switch to Run My Code" note (in Step Through the game itself says so). A failing
check still returns a hint (what the test saw); it is never shown, but the Mac harness reads it to
tell the mistakes apart (`expected.tsv`). The Hints pages are the place for help.
- The wiring is inside `func _startGamePage()` on purpose: Swift checks function bodies after every
  top-level declaration, so a function the student declares twice gets only "invalid redeclaration" on
  the student's own line, never "ambiguous use" in the hidden code.
- `GameWiring.start()` calls `GameLauncher.launch(box)`: the iPad one (`Engine.swift`) shows the live
  view; the Mac one (`Headless.swift`) keeps the box for `runHarness()`.

### Coyote Time support

- **The jump log** (`World.jumps`): every frame in which `updatePlayer` raised `speedY` above 0 (and
  not on an ouch), with the engine's own counts: from the ground or not, frames in the air, frames
  since ▲, and whether it was a second jump in mid-air. A 🍄 or stomp bounce comes from an event, so
  it is not a jump. The Coyote Time checks read it (they never read the student's variables), and so
  does the inspector line on Coyote Time: `last jump: 3 frames after the ledge 🐺 (coyote time)`,
  `from the ground, 4 frames before the edge`, `from the ground, without ▲!`, `in mid-air!`.
- **The cool-down.** The student's top-level vars (like `framesInAir`) keep their
  numbers from one test drive to the next. While a page's checks run, every drive starts with 12
  frames of standing still on a tiny floor (a throwaway world whose sounds, bursts and messages go
  nowhere), and one more runs after the last check, so the real level starts settled too. It puts
  the game's numbers and level number back, so its frames never change what a check measures. Engine
  rule tests and tools drive without it.
- **The checklist's "Reach the 🚩" tick** counts only when the page's 🚩 event finished the level
  (asked for `game.win()` or `game.nextLevel()`), not on a touch: from Locked Flag on, the student's
  own event can lock the 🚩.

## Run the tests

```
zsh GameModules/Tests/run-tests.sh                 # (a) Mac harness and (b) iPad typecheck, about 3 minutes
zsh GameModules/Tests/run-tests.sh mac 09-crab     # only the Mac harness, only Crab Patrol
FUZZ=0 zsh GameModules/Tests/run-tests.sh mac      # no random-input runs: under a minute
zsh GameModules/Tests/run-tests.sh ios             # only the iPad typecheck
zsh GameModules/Tests/run-tests.sh prose           # only the chain and prose checks, a few seconds
CHAPTERS=<folder with Chapter9 and Chapter11-16> VARIANTS=<folder> EXPECTED=<file> zsh GameModules/Tests/run-tests.sh
```

Pages are found by the table at the top of `run-tests.sh` (slug, chapter, folder). A page that
doesn't exist yet is skipped with a note, along with its variants and its `expected.tsv` rows.

**Every mode** first runs `chain.py check` and **the prose check**, `check-prose.py` (it reads the
page files and needs no build; `python3 GameModules/Tests/check-prose.py` runs it alone). A page's
answer is the code lines its finished code adds to its starter, 8 characters or more, and the
pieces of those lines that would give most of one away: an if's condition, the right side of an
`=`, or what's in a pair of parentheses, 12 characters or more with an operator or a comma
(`game.timer / 60`), that the starter doesn't already show.
- **Code pages:** the prose shows no line or piece of its own answer or of any later page's; it has
  a `## Your turn` with 1-3 bullets and one `**Your tools:**` line (not Design Your Own Game), no
  `**Controls:**` line after page 1, at most 100 words (Walk 140, Design Your Own Game 300; words
  have a letter or a digit), and ends with its Stuck line.
- **Hints pages:** one per Part with code, listed last in its chapter's manifest; prose only
  (Manifest.plist and main.swift, no hidden code, Name "Hints: <Part>", HiddenByDefault, no
  poster); one "Finished this Part? Go to the next page: **<title>**." line that names the next
  Part's first code page (5. Coins for Hints: Moving); a `## <page title>` section per page of the
  Part, in order, each with `**Hint 1:**`, `**Hint 2:**` and `**Hint 3:**`; and no line or piece
  of an answer of its Part or a later one.
- **README:** no page's answer line with `=` or `{`, and no piece of any page's answer.

**(a) Mac harness.**
1. `EngineRules.swift` checks the engine's rules directly: one movement rule, side bumps keep speedX,
   facing, whole-number timers that never count by themselves, start functions after an ouch and always
   before the next update, `playerGotHurt` once per ouch (enemy, spikes, fall, `player.hurt()`) and a
   hurt inside it doing nothing, `startGame` first and never after an ouch, `updateGame` last and only
   in the real game or a `game: true` drive, `showText` (one frame, 8 lines, 40 characters), the game
   numbers the engine never touches, game over putting numbers and Settings back, banners keeping a
   same-frame message, springs and stars, `*` not a flag, all 21 built-ins doing nothing (nothing
   wins, hurts or shows a message), the inspector; effects, the synth and mixer, particles, weather,
   shake, backgrounds and layers, `game.spawn` and fireballs, the ▼ button, `game.nextLevel()`, every
   page's level, `game.soundVolume` (30 at first, kept to 0...100, the mixer's 0.5 x volume / 100,
   sounds still logged at 0, a Setting that the checks and game over put back); and Coyote Time: the jump log (ground, coyote, mid-air, without ▲, not a
   🍄 or a stomp), a tap jumping as high as a hold (171: no short hop), the cool-down only during
   checks (and never changing the game's numbers), the 🚩 tick only on a real finish, the header (no
   hint, "Almost! Fix the ❌ first.", "Can't find:" right away, at most 2), and the Coyote Time
   inspector line.
2. **Wiring.** Four pages with the same hidden code prove the first-line rule at run time for all 21
   functions: exact first lines run the page's own (0 built-ins); other labels, the v2 `deltaTime`
   form, or no functions run every built-in (21).
3. It builds GameAPI for the Mac (every engine file but `Engine.swift`, plus `Headless.swift`, which
   stands in for it, and the `Autopilot.swift` bot) and runs every version of every page:
   - each page's **starter** and **solution**, read straight from the page files the way
     `inject_solutions.sh` ships them (the student page, and the answer-key page);
   - the **variants** in `variants/<slug>/*.swift`: likely mistakes (`wrong-*`), other right answers
     (`alt-*`, `try-*`, `stretch-*`, and the sandbox's `idea-*`, each Ideas recipe as a student would
     type it), and `fallback-*` versions that prove the first-line rule (the header names each one:
     `Can't find:` and its exact first line). Each is the page's whole visible
     code, with every function of the chain so far; the test puts it under the page's real hidden code.

   For each version it runs the page's checks, lets the bot play the real level (10 seeds of 60 s),
   and for starters and `wrong-*` versions (not Design Your Own Game) plays 500 runs with random
   buttons.
4. **BEEWINDOW** (Busy Bees solution, with all the chain's code): Mark's "the bees need more space",
   measured on the real level. Every tunnel bee's shortest open window must be at least 75 frames and
   4x the 16-frame crossing, the longest closed stretch at most 45 frames, the bob may not drift over
   a minute, holding ▶ blindly from a random moment must pass every bee at least 20% of the time, the
   bot must finish 29 of 30 seeds with a mean of 15 s or less and at most 0.5 hits per seed, and random
   buttons may reach the 🚩 in at most 1% of 300 runs. (Now: 81 frames, 39 frames, no drift, 48/120,
   30/30 at 10.6 s with 0.03 hits, 0/300.)

`check-results.py` compares everything with `expected.tsv`: the ✅/❌ pattern, the first failing
check's hint (never shown to the student; it tells the mistakes apart), whether the bot can finish,
the header's "Can't find:" warning, BEEWINDOW, and that random input never completes a page (and
never reaches an unlocked 🚩 on the `gate` starters). A version folder with no row in `expected.tsv`
(for example an iCloud "name 2.swift" copy) and a row with no version (a deleted variant) both fail
the run. v6 dropped v5's hint check (no answer line in a hint, at most 170 characters), because no
hint is shown any more; the prose check still guards every word the student sees.

**(b) iPad typecheck.** Typechecks the engine for iPad in Swift 6 and Swift 5 against the book's
PlaygroundSupport, refuses the symbols the iPad can't see (as `inject_solutions.sh` step 4 does), and
fails if its typecheck takes more than 1.35x the v3 engine's (`v3-archive/engine`, the engine Mark
ran on his iPad, timed in turn with this one, best of 3 each, so a busy Mac slows both; v4 is
0.9x to 1.1x) or any function body or expression takes over 300 ms (the slowest is about 40 to 70 ms). Then
every page as shipped, as the student page and as the answer-key page, every variant, and the compile
probes, with `-warn-long-expression-type-checking=200` (an "ok" probe may have no warning at all):
friendly errors (`player.x += 2.5`, `"⭐ " + game.score`, `game.showText(game.score)`,
`game.playSound("coin")`), `game.soundVolume`, `justReleased` being gone, fast string chains, and for each of the 21 functions: left out, another
label, another type and the v2 `deltaTime: Double` form all compile with nothing in the hidden code,
and written twice gives "invalid redeclaration" on the student's line only.

## Check the built books

After building the RobotPlaygroundBook scheme:

```
zsh GameModules/Tests/check-book.sh <DerivedData>/Build/Products/Release-iphoneos
```

It checks both Game Design books (SwiftVersion 5.x, only Chapter9 and Chapter11-16, in order, only GameAPI, the icon, chapter and
page manifests, posters, no solution text in the student book, every answer-key page's code is its
solution), typechecks every page with code of both books against the book's own copy of the engine
(0 warnings: a warning is a yellow triangle on the iPad) and runs them, redraws all 23 posters with
make-posters.sh and fails if one is out of date (or isn't 1024 x 1024), and confirms that no other book contains GameAPI
or lists a Game Design chapter.

## Changing a page

**Code:** change the page's step in `GameModules/Tools/chain.py` (its stub or its answer), then
`python3 -I GameModules/Tools/chain.py sync` to rewrite every page's code from the chain (each
page's prose stays). A change to a page's answer carries into every later page's starter and
solution, so later variants that contain that code need the same change (they are whole pages: a
`grep -rl` for the old line finds them). **Prose:** edit the page's `/*: ... */` card directly in
its `main.swift`, and its Part's Hints page (`Hints<Part>.playgroundpage`); `chain.py sync` never
touches either. Then `zsh GameModules/Tests/run-tests.sh prose`.

The pages teach these rules: every function gets its thing as a parameter (`startCrab(crab:)`,
`updateCrab(crab:)`), the engine moves everything by `speedX` / `speedY` (a check that sees a thing
moved by changing its `x` or `y` says so), and every number is a whole number: timers count frames
(60 frames is 1 second). Each page's starter must define every function in that page's
`PageInfo.functions` (`Pages.swift`), or the header warns about it (`Can't find:`).

- In `main.swift`, the solution is the commented block after `// MARK: - Solution` at the end of the
  hidden code; it must stay the last thing before `//#-end-hidden-code` (`chain.py sync` writes it).
- Prose and Hints pages never show a line of the page's answer: the prose check fails the run.
  (Check hints are never shown.)
- The pages need Swift 5 language mode (`SwiftVersion` 5.x in the book's manifest; step 4 and
  `check-book.sh` check it): in Swift 6 mode a var at the top of a page, like `framesInAir`, can't be
  changed inside a function ("main actor-isolated var").
- Every "write here" comment in a starter starts with 👉 (the banner too), so it's easy to find in a
  long page.
- Coyote Time's "used up" number must be at least its window (`framesInAir = 6` under
  `framesInAir < 6`): with a window of 10 and a used-up 6, ▲ jumps again on air frames 7-9, and
  holding ▲ flies (`04-coyote/wrong-window-10-usedup-6`).
- The bee pattern (Busy Bees and every later page) is up at speed 2 while `bee.timer < 60`, down
  after that, count with `bee.timer += 1`, and start over when `bee.timer == 120`: exactly 60 frames
  each way, so the bob never drifts. The bee tunnels are 3 squares tall.
- The posters are square title cards (the Part, an emoji, the page title, "▶ Run My Code to play"),
  drawn by `zsh GameModules/Tools/make-posters.sh` from the page and chapter manifests, with every
  word inside the central half so any crop the live view makes keeps them. Rerun it after renaming or
  adding a page (the emoji per page is a table in `make-posters.swift`); levels aren't drawn.
- Level 2's starter map is `Levels.level2Starter` in `Pages.swift`; its check counts the letters
  changed from it, so keep the two the same.
- `GameModules/Tools/make-icon.swift` draws `GameModules/gameicon.png`
  (`swift GameModules/Tools/make-icon.swift GameModules/gameicon.png`).

`Headless.swift` also has an `IDLE=<seconds>` setting that reports when a player who touches
nothing first gets hurt (useful when moving enemies in the sandbox), `TRACEBOT=<frames>` prints where
the bot is (and what `showText` shows) every that many frames, and the RESULT `texts=` line lists
every `showText` line the bot's game showed (digits as #). The bot (`Autopilot.swift`) heads for the
🚩 (or the next coin or crab while it's locked, and every coin first from Locked Flag on), climbs
block tops toward a goal more than a jump above, waits for the ledge's last frame before a gap 4 or
more squares wide, holds ▲ while rising (left over from v5's Short Hop; harmless now), and taps ▼
at enemies ahead.

`v3-archive/` holds the v3 variants and `expected.tsv` (the v4 ones were converted from them), and
`v3-archive/engine`, the v3 engine's sources: `run-tests.sh ios` only typechecks it, as the yardstick
for the engine's typecheck time.
