#!/usr/bin/env python3
"""The v4 Game Design chain, as data: every page's starter and finished code (an authoring and test
tool; the Xcode build never runs it).

starter(N) = STUB(N) applied to solution(N-1);  solution(N) = SOLVE(N) applied to starter(N).
The code is a fixed list of sections (LEVELS, SETTINGS, VARIABLES, PLAYER, GAME, ENEMIES,
FIREBALLS, EVENTS); a section's header appears the first time it has code. Each page starts with a
one-line banner (`// 👉 THIS PAGE: ...`) that the next page's starter replaces. Every edit's anchor
must match exactly once, or it stops with an AssertionError naming the anchor.

The test versions in GameModules/Tests/variants were made from this chain's code (each is a whole
page's visible code), and the tests' expected.tsv was measured on pages made by `pages` below.

Usage (Python 3, standard library only):
  python3 -I GameModules/Tools/chain.py check [Chapters]  checks the book's pages (default: the repo's
        PlaygroundBook/Chapters) against the chain: every page's hidden code, solution block and
        starter are exactly the chain's, every starter is the previous page's finished code plus
        inserted lines only (its stub), and every page but the last ends its prose with its Stuck line
        (stuck_line below). Prose-only pages (README, the Hints pages) are not in the chain; the prose
        check (GameModules/Tests/check-prose.py) checks them. run-tests.sh and check-book.sh run it.
  python3 -I GameModules/Tools/chain.py sync [Chapters]   after changing the chain here: rewrites every
        page's hidden code, solution block and starter from the chain, and keeps each page's prose
        card as it is. (A new page needs its folder, Manifest.plist and prose card first.) Then run
        make-posters.sh if a page is renamed or added, and the tests: later pages' variants carry earlier code.
  python3 -I GameModules/Tools/chain.py dump <outdir>     writes <outdir>/NN-slug/{starter,solution}.swift
  python3 -I GameModules/Tools/chain.py pages <folder>    writes TEST pages (the real hidden code + the
        solution block + the starter, with a one-line prose card ending in the Stuck line), a
        one-line README, a minimal Hints page per Part and the chapter manifests, in the book's
        folder layout (Chapter9 and Chapter11-16), for run-tests.sh with CHAPTERS=<folder>. Never the book's
        Chapters folder: the real pages have real prose.
"""
import os
import sys

SECTIONS = [
    ("LEVELS", "// ========== 🗺️ LEVELS =========="),
    ("SETTINGS", "// ========== ⚙️ SETTINGS =========="),
    ("VARIABLES", "// ========== 🔢 VARIABLES =========="),
    ("PLAYER", "// ========== 🙂 PLAYER =========="),
    ("GAME", "// ========== 🎮 GAME =========="),
    ("ENEMIES", "// ========== 🦀 ENEMIES =========="),
    ("FIREBALLS", "// ========== 🔥 FIREBALLS =========="),
    ("EVENTS", "// ========== ⚡ EVENTS =========="),
]

# (slug, GamePage case, chapter, folder, title)
PAGES = [
    ("01-walk", "walk", "Chapter9", "Walk", "1. Walk"),
    ("02-fall", "fall", "Chapter9", "Fall", "2. Fall"),
    ("03-jump", "jump", "Chapter9", "Jump", "3. Jump"),
    ("04-coyote", "coyote", "Chapter9", "CoyoteTime", "4. Coyote Time"),
    ("05-coins", "coins", "Chapter11", "Coins", "5. Coins"),
    ("06-score", "score", "Chapter11", "ShowTheScore", "6. Show the Score"),
    ("07-sounds", "sounds", "Chapter11", "Sounds", "7. Sounds"),
    ("08-sparkles", "sparkles", "Chapter11", "Sparkles", "8. Sparkles"),
    ("09-crab", "crab", "Chapter12", "CrabPatrol", "9. Crab Patrol"),
    ("10-bee", "bee", "Chapter12", "BusyBees", "10. Busy Bees"),
    ("11-ghost", "ghost", "Chapter12", "GhostChase", "11. Ghost Chase"),
    ("12-stomp", "stomp", "Chapter12", "Stomp", "12. Stomp"),
    ("13-heromoves", "heroMoves", "Chapter13", "HeroMoves", "13. Hero Moves"),
    ("14-backgrounds", "backgrounds", "Chapter13", "Backgrounds", "14. Backgrounds"),
    ("15-boing", "boing", "Chapter14", "Boing", "15. Boing!"),
    ("16-starpower", "starPower", "Chapter14", "StarPower", "16. Star Power"),
    ("17-fireballs", "fireballs", "Chapter14", "Fireballs", "17. Fireballs"),
    ("18-stopwatch", "stopwatch", "Chapter15", "Stopwatch", "18. Stopwatch"),
    ("19-deathcounter", "deathCounter", "Chapter15", "DeathCounter", "19. Death Counter"),
    ("20-lives", "lives", "Chapter15", "LivesAndGameOver", "20. Lives and Game Over"),
    ("21-lockedflag", "lockedFlag", "Chapter15", "LockedFlag", "21. Locked Flag"),
    ("22-level2", "level2", "Chapter15", "Level2", "22. Level 2"),
    ("23-design", "design", "Chapter16", "DesignYourOwnGame", "23. Design Your Own Game"),
]

# chapter: (Part name, its prose-only Hints page folder or None). Each Part with code pages ends
# with "Hints: <Part name>" (Part 7 has README instead). Chapter manifests list the code pages in
# PAGES order, then the Hints page. There is no Chapter10 since v7: its Part (Coyote Time) joined
# Part 1, and the later folders kept their names.
PARTS = {
    "Chapter9": ("Part 1: Moving", "HintsMoving"),
    "Chapter11": ("Part 2: Coins and Effects", "HintsCoinsAndEffects"),
    "Chapter12": ("Part 3: Enemies", "HintsEnemies"),
    "Chapter13": ("Part 4: Looks", "HintsLooks"),
    "Chapter14": ("Part 5: Power-ups", "HintsPowerUps"),
    "Chapter15": ("Part 6: Rules of the Game", "HintsRulesOfTheGame"),
    "Chapter16": ("Part 7: Your Game", None),
}


def hints_title(chapter):
    """ "Hints: Moving" for Chapter9: the Hints page's Name and its card's title."""
    return "Hints: " + PARTS[chapter][0].split(": ", 1)[1]


def stuck_line(slug):
    """The last line of a page's prose card (None for the last page, which has no next page):
    the Part's Hints page first, then the page with the finished code. The last page of a Part
    names that page, because its Hints page comes in between."""
    i = [p[0] for p in PAGES].index(slug)
    if i == len(PAGES) - 1:
        return None
    chapter, following = PAGES[i][2], PAGES[i + 1]
    then = "The next page" if following[2] == chapter else "**" + following[4] + "**"
    return "Stuck? Open **" + hints_title(chapter) + "**. Still stuck? " + then + " has the finished code."


class Code:
    """The page's code: a banner and, per section, a list of blocks (each a multi-line string)."""

    def __init__(self):
        self.banner = ""
        self.sections = {name: [] for name, _ in SECTIONS}

    def copy(self):
        c = Code()
        c.banner = self.banner
        c.sections = {k: list(v) for k, v in self.sections.items()}
        return c

    def text(self):
        out = [self.banner, ""]
        for name, header in SECTIONS:
            blocks = self.sections[name]
            if not blocks:
                continue
            out.append(header)
            out.append("\n\n".join(blocks))
            out.append("")
        return "\n".join(out).rstrip("\n") + "\n"

    # ---- edits (every anchor must match exactly once) ----
    def add(self, section, block, first=False, after_block=None):
        blocks = self.sections[section]
        if after_block is not None:
            idx = [i for i, b in enumerate(blocks) if after_block in b]
            assert len(idx) == 1, ("after_block", after_block, idx)
            blocks.insert(idx[0] + 1, block)
        elif first:
            blocks.insert(0, block)
        else:
            blocks.append(block)

    def replace(self, old, new):
        hits = [(n, i) for n, bl in self.sections.items() for i, b in enumerate(bl) if old in b]
        assert len(hits) == 1 and self.sections[hits[0][0]][hits[0][1]].count(old) == 1, ("replace", old, hits)
        n, i = hits[0]
        self.sections[n][i] = self.sections[n][i].replace(old, new)

    def func_end(self, first_line, text):
        """Inserts text (lines, already indented) right before the closing } of that function."""
        hits = [(n, i) for n, bl in self.sections.items() for i, b in enumerate(bl) if first_line in b]
        assert len(hits) == 1, ("func_end", first_line, hits)
        n, i = hits[0]
        b = self.sections[n][i]
        start = b.index(first_line)
        end = b.index("\n}", start)
        self.sections[n][i] = b[:end] + "\n" + text + b[end:]


def page_steps():
    """[(banner, stub(code), solve(code))] for the 23 pages."""
    steps = []

    # ---------- 1. Walk ----------
    def stub1(c):
        c.add("PLAYER", '''// The player's start function. Runs once when the level starts, and again after every ouch.
func startPlayer(player: Player) {
    player.emoji = "🙂"   // your hero: try "🐱", "🤖" or "🦊"
}''')
        c.add("PLAYER", '''// The player's update function. Runs 60 times a second.
func updatePlayer(player: Player) {
    // Walk:
    if isPressed(.right) {
        player.speedX = 6
    }
    // 👉 ◀ walks left. No button: stand still.

}''')
        c.add("EVENTS", '''// Runs every frame you touch the 🚩.
func playerTouchedFlag() {
    game.win()
}''')

    def solve1(c):
        c.replace('''    }
    // 👉 ◀ walks left. No button: stand still.

}''', '''    } else if isPressed(.left) {
        player.speedX = -6
    } else {
        player.speedX = 0
    }
}''')
    steps.append(("make ◀ walk left, and stop when no button is held.", stub1, solve1))

    # ---------- 2. Fall ----------
    def stub2(c):
        c.func_end("func updatePlayer(player: Player) {", "    // 👉 Gravity: pull you down a little more every frame.\n")

    def solve2(c):
        c.replace("    // 👉 Gravity: pull you down a little more every frame.\n", "    // Gravity:\n    player.speedY -= 1")
    steps.append(("make gravity pull you down.", stub2, solve2))

    # ---------- 3. Jump ----------
    def stub3(c):
        c.func_end("func updatePlayer(player: Player) {", '''    // 👉 Jump: (bug: hold ▲ and you fly!)
    if isPressed(.up) {
        player.speedY = 18
    }''')
        c.add("EVENTS", '''// Runs once for every ouch (an enemy, spikes, a fall or player.hurt()).
func playerGotHurt() {
    game.showMessage("Ouch!")
}''', first=True)

    def solve3(c):
        c.replace('''    // 👉 Jump: (bug: hold ▲ and you fly!)
    if isPressed(.up) {
        player.speedY = 18
    }''', '''    // Jump (only from the ground):
    if isPressed(.up) {
        if player.isOnGround() {
            player.speedY = 18
        }
    }''')
    steps.append(("jump only from the ground.", stub3, solve3))

    # ---------- 4. Coyote Time ----------
    def stub4(c):
        c.add("VARIABLES", '''// A var up here, outside every function, keeps its number from frame to frame.
// Coyote time: how many frames since you last stood on a block.
var framesInAir = 0''')
        c.replace("    // Jump (only from the ground):\n", "    // 👉 Coyote time: count framesInAir here.\n\n    // Jump (only from the ground):\n")

    def solve4(c):
        c.replace('''    // 👉 Coyote time: count framesInAir here.

''', '''    // Coyote time: count the frames since you stood on a block.
    if player.isOnGround() {
        framesInAir = 0
    } else {
        framesInAir += 1
    }
''')
        c.replace('''    // Jump (only from the ground):
    if isPressed(.up) {
        if player.isOnGround() {
            player.speedY = 18
        }
    }''', '''    // Jump: from the ground, or up to 5 frames after you leave it.
    if isPressed(.up) {
        if framesInAir < 6 {
            player.speedY = 18
            framesInAir = 6   // used up: no second jump until you land
        }
    }''')
    steps.append(("you can still jump for a moment after you run off a ledge.", stub4, solve4))

    # ---------- 5. Coins ----------
    def stub5(c):
        c.add("EVENTS", '''// Runs every frame you touch a 🪙. coin is that coin.
func playerTouchedCoin(coin: Coin) {

}''', first=True)

    def solve5(c):
        c.replace('''func playerTouchedCoin(coin: Coin) {

}''', '''func playerTouchedCoin(coin: Coin) {
    game.score += 1
    coin.remove()
}''')
    steps.append(("every coin adds 1 to the score, once, and disappears.", stub5, solve5))

    # ---------- 6. Show the Score ----------
    def stub6(c):
        c.add("GAME", '''// The game's update function. Runs 60 times a second, after every other function.
func updateGame(game: Game) {
    // 👉 Show the score here.

}''')

    def solve6(c):
        c.replace('''    // 👉 Show the score here.

''', '''    game.showText("⭐ " + String(game.score))
''')
    steps.append(("show the score at the top right, every frame.", stub6, solve6))

    # ---------- 7. Sounds ----------
    def stub7(c):
        pass

    def solve7(c):
        c.replace("    game.score += 1\n    coin.remove()", "    game.score += 1\n    game.playSound(.coin)\n    coin.remove()")
        c.replace("            framesInAir = 6   // used up: no second jump until you land\n",
                  "            framesInAir = 6   // used up: no second jump until you land\n            game.playSound(.jump)\n")
    steps.append(("a coin plays a sound, and so does every jump.", stub7, solve7))

    # ---------- 8. Sparkles ----------
    def stub8(c):
        pass

    def solve8(c):
        c.replace("    game.playSound(.coin)\n    coin.remove()", "    game.playSound(.coin)\n    coin.burst(\"✨\")\n    coin.remove()")
        c.replace("            game.playSound(.jump)\n",
                  "            game.playSound(.jump)\n            player.burst(\"💨\", count: 6, speed: 2)\n")
    steps.append(("sparkles where you grab a coin, and a puff of dust when you jump.", stub8, solve8))

    # ---------- 9. Crab Patrol ----------
    def stub9(c):
        c.add("ENEMIES", '''// Runs once for EACH 🦀 when the level starts, and again after every ouch. crab is that crab.
func startCrab(crab: Crab) {
    // 👉 Step 1: give the crab a speed.

}''')
        c.add("ENEMIES", '''// Runs 60 times a second for EACH 🦀. crab is the crab whose turn it is.
func updateCrab(crab: Crab) {
    // 👉 Step 2: at a wall, flip its speed.

}''')
        c.add("EVENTS", '''// Runs every frame you touch an enemy. enemy is that enemy.
func playerTouchedEnemy(enemy: Enemy) {
    player.hurt()
}''', after_block="func playerTouchedCoin(coin: Coin) {")

    def solve9(c):
        c.replace('''func startCrab(crab: Crab) {
    // 👉 Step 1: give the crab a speed.

}''', '''func startCrab(crab: Crab) {
    crab.speedX = -2
}''')
        c.replace('''func updateCrab(crab: Crab) {
    // 👉 Step 2: at a wall, flip its speed.

}''', '''func updateCrab(crab: Crab) {
    if crab.facingWall() {
        crab.speedX = -crab.speedX
    }
}''')
    steps.append(("every crab walks, and turns around at walls.", stub9, solve9))

    # ---------- 10. Busy Bees ----------
    def stub10(c):
        c.add("ENEMIES", '''// Runs 60 times a second for EACH 🐝. bee is the bee whose turn it is.
func updateBee(bee: Bee) {
    // 👉 Step 1: fly up when bee.timer is less than 60 (1 second). Otherwise fly down.

    // Count frames. 60 frames is 1 second:
    bee.timer += 1
    // 👉 Step 2: start over when bee.timer gets to 120.

}''')

    def solve10(c):
        c.replace('''    // 👉 Step 1: fly up when bee.timer is less than 60 (1 second). Otherwise fly down.

''', '''    // Up for 1 second, then down:
    if bee.timer < 60 {
        bee.speedY = 2
    } else {
        bee.speedY = -2
    }
''')
        c.replace('''    // 👉 Step 2: start over when bee.timer gets to 120.

''', '''    // Start over after 2 seconds:
    if bee.timer == 120 {
        bee.timer = 0
    }
''')
    steps.append(("every bee flies up for 1 second, then down for 1 second, forever.", stub10, solve10))

    # ---------- 11. Ghost Chase ----------
    def stub11(c):
        c.add("ENEMIES", '''// Runs 60 times a second for EACH 👻. ghost is the ghost whose turn it is.
// Ghosts float right through blocks.
func updateGhost(ghost: Ghost) {
    // Chase left and right:
    if player.x > ghost.x {
        ghost.speedX = 1
    } else {
        ghost.speedX = -1
    }
    // 👉 Chase up and down: the same idea, with y.

}''')

    def solve11(c):
        c.replace('''    // 👉 Chase up and down: the same idea, with y.

''', '''    // Chase up and down:
    if player.y > ghost.y {
        ghost.speedY = 1
    } else {
        ghost.speedY = -1
    }
''')
    steps.append(("the ghost chases you up and down too.", stub11, solve11))

    # ---------- 12. Stomp ----------
    def stub12(c):
        c.replace('''func playerTouchedEnemy(enemy: Enemy) {
    player.hurt()
}''', '''func playerTouchedEnemy(enemy: Enemy) {
    // 👉 Land on top: squish it. Walk into it: ouch.
    player.hurt()
}''')

    def solve12(c):
        c.replace('''    // 👉 Land on top: squish it. Walk into it: ouch.
    player.hurt()
}''', '''    if player.speedY < 0 {
        // Falling onto it: squish it and bounce.
        enemy.remove()
        player.speedY = 12
    } else {
        // Walked into it: ouch!
        player.hurt()
    }
}''')
    steps.append(("land on an enemy to squish it; walking into one still hurts.", stub12, solve12))

    # ---------- 13. Hero Moves ----------
    def stub13(c):
        c.func_end("func updatePlayer(player: Player) {", "    // 👉 How you look: standing, walking, and in the air.\n")

    def solve13(c):
        # From here on "How you look" sets player.emoji every frame, so startPlayer's comment says so.
        c.replace('''    player.emoji = "🙂"   // your hero: try "🐱", "🤖" or "🦊"''', '''    player.emoji = "🙂"   // your looks are now in "How you look", in updatePlayer''')
        c.replace("    // 👉 How you look: standing, walking, and in the air.\n", '''    // How you look:
    if player.isOnGround() {
        if player.speedX == 0 {
            player.emoji = "🧍"
        } else {
            player.emoji = "🏃"
        }
    } else {
        player.emoji = "🤸"
    }''')
    steps.append(("your hero looks different standing, walking and in the air.", stub13, solve13))

    # ---------- 14. Backgrounds ----------
    def stub14(c):
        c.add("SETTINGS", '''// The sky, and a row of mountains far behind the level.
game.skyColor = .hex("3a7bd5")
// 👉 Step 1: the bottom of the sky.

game.addLayer("⛰️  🏔️   ⛰️ 🏔️    ", y: 0, size: 220, distance: 5)
// 👉 Step 2: a closer layer.''')

    def solve14(c):
        c.replace('''// The sky, and a row of mountains far behind the level.
game.skyColor = .hex("3a7bd5")
// 👉 Step 1: the bottom of the sky.

game.addLayer("⛰️  🏔️   ⛰️ 🏔️    ", y: 0, size: 220, distance: 5)
// 👉 Step 2: a closer layer.''', '''// The sky fades from skyColor (top) to horizonColor (bottom).
game.skyColor = .hex("3a7bd5")
game.horizonColor = .hex("ffd194")
// Layers far behind the level. A bigger distance scrolls slower.
game.addLayer("⛰️  🏔️   ⛰️ 🏔️    ", y: 0, size: 220, distance: 5)
game.addLayer("🌲 🌳🌲   🌲🌲 ", y: 64, size: 100, distance: 2)''')
    steps.append(("a sky that fades, and two layers that scroll at different speeds.", stub14, solve14))

    # ---------- 15. Boing! ----------
    def stub15(c):
        c.add("EVENTS", '''// Runs every frame you touch a 🍄. spring is that spring.
func playerTouchedSpring(spring: Spring) {

}''', after_block="func playerTouchedCoin(coin: Coin) {")

    def solve15(c):
        c.replace('''func playerTouchedSpring(spring: Spring) {

}''', '''func playerTouchedSpring(spring: Spring) {
    player.speedY = 25
}''')
    steps.append(("a 🍄 bounces you over a tall wall.", stub15, solve15))

    # ---------- 16. Star Power ----------
    def stub16(c):
        c.add("EVENTS", '''// Runs every frame you touch a ⭐. star is that star.
func playerTouchedStar(star: Star) {

}''', after_block="func playerTouchedSpring(spring: Spring) {")
        c.func_end("func updatePlayer(player: Player) {", "    // 👉 Star power: count player.timer down here, and change how you look while it lasts.\n")
        c.replace('''func playerTouchedEnemy(enemy: Enemy) {
    if player.speedY < 0 {''', '''func playerTouchedEnemy(enemy: Enemy) {
    // 👉 Star power first: with a ⭐, plow right through.
    if player.speedY < 0 {''')

    def solve16(c):
        c.replace('''func playerTouchedStar(star: Star) {

}''', '''func playerTouchedStar(star: Star) {
    star.remove()
    player.timer = 300
}''')
        c.replace("    // 👉 Star power: count player.timer down here, and change how you look while it lasts.\n", '''    // Star power: count down, and look like a star.
    if player.timer > 0 {
        player.timer -= 1
        player.emoji = "🤩"
    }''')
        c.replace('''    // 👉 Star power first: with a ⭐, plow right through.
    if player.speedY < 0 {''', '''    if player.timer > 0 {
        // Star power: plow right through.
        enemy.remove()
    } else if player.speedY < 0 {''')
    steps.append(("a ⭐ lets you plow through enemies for 5 seconds.", stub16, solve16))

    # ---------- 17. Fireballs ----------
    def stub17(c):
        c.add("FIREBALLS", '''// Runs 60 times a second for EACH 🔥. fireball is the fireball whose turn it is.
func updateFireball(fireball: Fireball) {
    if fireball.facingWall() {
        fireball.remove()
    }
}''')
        c.add("EVENTS", '''// Runs every frame a 🔥 touches an enemy. fireball is that fireball; enemy is that enemy.
func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {

}''', after_block="func playerTouchedEnemy(enemy: Enemy) {")
        c.func_end("func updatePlayer(player: Player) {", "    // 👉 When ▼ is just pressed (justPressed), throw a fireball the way you face.\n")

    def solve17(c):
        c.replace("    // 👉 When ▼ is just pressed (justPressed), throw a fireball the way you face.\n", '''    // ▼ throws a fireball the way you face:
    if justPressed(.down) {
        if player.facingRight() {
            game.spawn(.fireball, x: player.x, y: player.y, speedX: 12, speedY: 0)
        } else {
            game.spawn(.fireball, x: player.x, y: player.y, speedX: -12, speedY: 0)
        }
    }''')
        c.replace('''func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {

}''', '''func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {
    enemy.remove()
    fireball.remove()
}''')
    steps.append(("▼ throws a 🔥 that knocks out enemies.", stub17, solve17))

    # ---------- 18. Stopwatch ----------
    def stub18(c):
        c.replace('''    game.showText("⭐ " + String(game.score))
''', '''    game.showText("⭐ " + String(game.score))
    // 👉 Stopwatch: count frames, and show whole seconds.

''')

    def solve18(c):
        c.replace('''    // 👉 Stopwatch: count frames, and show whole seconds.

''', '''    // Stopwatch: count frames. 60 frames is 1 second.
    game.timer += 1
    game.showText("⏱ " + String(game.timer / 60))
''')
    steps.append(("a stopwatch that shows the seconds.", stub18, solve18))

    # ---------- 19. Death Counter ----------
    def stub19(c):
        pass

    def solve19(c):
        c.replace('''    game.showMessage("Ouch!")
''', '''    game.showMessage("Ouch!")
    game.deaths += 1
''')
        c.func_end("func updateGame(game: Game) {", '''    game.showText("💥 " + String(game.deaths))''')
    steps.append(("count every ouch, and show the count.", stub19, solve19))

    # ---------- 20. Lives and Game Over ----------
    def stub20(c):
        c.add("GAME", '''// The game's start function. Runs once when the game starts, and again when it starts over
// (after game over, or when you play again after a win).
func startGame(game: Game) {

}''', first=True)

    def solve20(c):
        c.replace('''func startGame(game: Game) {

}''', '''func startGame(game: Game) {
    game.lives = 3
}''')
        c.replace('''    game.deaths += 1
''', '''    game.deaths += 1
    game.lives -= 1
    if game.lives == 0 {
        game.lose()
    }
''')
        c.func_end("func updateGame(game: Game) {", '''    game.showText("❤️ " + String(game.lives))''')
    steps.append(("3 lives, one lost for every ouch, and game over at 0.", stub20, solve20))

    # ---------- 21. Locked Flag ----------
    def stub21(c):
        pass

    def solve21(c):
        c.replace('''func playerTouchedFlag() {
    game.win()
}''', '''func playerTouchedFlag() {
    if game.coinsLeft == 0 {
        game.win()
    } else {
        game.showMessage("🪙 " + String(game.coinsLeft) + " coins left!")
    }
}''')
    steps.append(("the 🚩 waits until every coin is collected.", stub21, solve21))

    # ---------- 22. Level 2 ----------
    def stub22(c):
        c.add("LEVELS", '''// Level 2: the map you play after level 1's 🚩. Each line is one row of squares.
game.level2 = """
..............................
...~..........~...........~...
..............................
..............................
..............................
.........ooo..................
........#####.................
.P...#..............c...#....F
##############..##############
"""''')

    def solve22(c):
        c.replace('''.........ooo..................
........#####.................
.P...#..............c...#....F''', '''......o..ooo.......o..........
........#####.................
.P...#..............c...#.c..F''')
        c.replace('''    if game.coinsLeft == 0 {
        game.win()''', '''    if game.coinsLeft == 0 {
        game.nextLevel()''')
    steps.append(("make level 2 your own, and send the 🚩 to it.", stub22, solve22))

    # ---------- 23. Design Your Own Game ----------
    def stub23(c):
        c.add("LEVELS", '''// Level 1: your map. Each line is one row of squares.
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
"""''', first=True)

    def solve23(c):
        # The answer key is the hook demo: 🦊 at sunset, a bat that chases only when you're close,
        # a ⭐ and a 🍄 in the map, and stomps you can hear and feel.
        c.replace('''..P...#........c...#..^^..#...#####..f...F''', '''..P...#..*.....c...#..^^..#.s.#####..f...F''')
        c.replace('''game.skyColor = .hex("3a7bd5")
game.horizonColor = .hex("ffd194")''', '''game.skyColor = .hex("2b1b4a")
game.horizonColor = .hex("ff8a5c")
game.ghostEmoji = "🦇"''')
        c.replace('''    player.emoji = "🙂"   // your looks are now in "How you look", in updatePlayer''', '''    player.emoji = "🦊"''')
        c.replace('''    // How you look:
    if player.isOnGround() {
        if player.speedX == 0 {
            player.emoji = "🧍"
        } else {
            player.emoji = "🏃"
        }
    } else {
        player.emoji = "🤸"
    }
''', '''    // How you look:
    player.emoji = "🦊"
''')
        c.replace('''func updateGhost(ghost: Ghost) {
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
}''', '''func updateGhost(ghost: Ghost) {
    // A bat: it chases only when you're close.
    ghost.speedX = 0
    ghost.speedY = 0
    if player.x > ghost.x - 300 {
        if player.x < ghost.x + 300 {
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
    }
}''')
        c.replace('''        // Falling onto it: squish it and bounce.
        enemy.remove()
        player.speedY = 12''', '''        // Falling onto it: squish it and bounce.
        game.playSound(.stomp)
        enemy.burst("💥")
        game.shake()
        enemy.remove()
        player.speedY = 12''')
    steps.append(("your game. Change anything!", stub23, solve23))
    return steps


def chain():
    """[(starter Code, solution Code)] for the 23 pages."""
    out = []
    code = Code()
    for banner, stub, solve in page_steps():
        start = code.copy()
        start.banner = "// 👉 THIS PAGE: " + banner
        stub(start)
        done = start.copy()
        solve(done)
        out.append((start, done))
        code = done
    return out


HIDDEN = '''//#-hidden-code
import GameAPI
func _startGamePage() {
    let wire = GameWiring(.%s)
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
'''


def commented(text):
    return "\n".join(("// " + l) if l.strip() else "//" for l in text.rstrip("\n").split("\n")) + "\n"


def split_page(text):
    """(code above the prose: hidden code and solution block, the prose card, the starter)."""
    lines = text.split("\n")
    e = lines.index("//#-end-hidden-code")
    c = lines.index(" */", e)
    if lines[e + 1] != "/*:" or lines[c + 1] != "":
        raise ValueError("the prose card must follow //#-end-hidden-code, then one blank line")
    return "\n".join(lines[:e + 1]) + "\n", "\n".join(lines[e + 1:c + 1]) + "\n", "\n".join(lines[c + 2:])


def page_from_chain(case, start, done, card):
    return HIDDEN % case + "// MARK: - Solution\n" + commented(done.text()) + "//#-end-hidden-code\n" + card + "\n" + start.text()


def book_pages(chapters):
    """[(slug, case, path, title, starter, solution)] for the book's 23 pages with code."""
    out = []
    for (slug, case, chapter, folder, title), (start, done) in zip(PAGES, chain()):
        path = os.path.join(chapters, chapter + ".playgroundchapter", "Pages", folder + ".playgroundpage", "main.swift")
        out.append((slug, case, path, title, start, done))
    return out


def check(chapters):
    import difflib
    problems = []
    previous = None
    for slug, case, path, title, start, done in book_pages(chapters):
        # The chain itself: a starter only adds lines to the previous page's finished code.
        if previous is not None:
            a, b = previous.text().split("\n")[1:], start.text().split("\n")[1:]
            ops = difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes()
            if any(op[0] not in ("equal", "insert") for op in ops):
                problems.append(slug + ": its stub changes or removes a line of the previous page's finished code")
        previous = done
        if not os.path.exists(path):
            problems.append(slug + ": no page at " + path)
            continue
        text = open(path, encoding="utf-8").read()
        try:
            top, card, starter = split_page(text)
        except ValueError as error:
            problems.append(slug + ": " + str(error))
            continue
        if not card.startswith("/*:\n # " + title + "\n"):
            problems.append(slug + ": the prose card doesn't start with its title, \"# " + title + "\"")
        stuck = stuck_line(slug)
        if stuck and card.rstrip("\n").split("\n")[-2] != " " + stuck:
            problems.append(slug + ": the prose doesn't end with \"" + stuck + "\"")
        want = page_from_chain(case, start, done, card)
        if text != want:
            wtop, _, wstarter = split_page(want)
            hidden, solution = top.split("// MARK: - Solution\n", 1) if "// MARK: - Solution\n" in top else (top, "")
            whidden, wsolution = wtop.split("// MARK: - Solution\n", 1)
            parts = [name for name, got, exp in (("hidden code", hidden, whidden), ("solution block", solution, wsolution),
                                                 ("starter", starter, wstarter)) if got != exp]
            problems.append(slug + ": its " + " and ".join(parts or ["text"]) + " differ from the chain (run chain.py sync?)")
    for p in problems:
        print("FAIL chain: " + p)
    if problems:
        return 1
    print("ok   chain: all %d pages are the chain's code (each starter = the previous page's finished code + its stub)" % len(PAGES))
    return 0


def sync(chapters):
    for slug, case, path, title, start, done in book_pages(chapters):
        if not os.path.exists(path):
            sys.exit(slug + ": no page at " + path + " (make its folder, Manifest.plist and prose card first)")
        text = open(path, encoding="utf-8").read()
        _, card, _ = split_page(text)
        want = page_from_chain(case, start, done, card)
        if want != text:
            open(path, "w", encoding="utf-8").write(want)
            print("updated " + os.path.relpath(path, chapters))


def main():
    mode = sys.argv[1]
    if mode in ("check", "sync"):
        here = os.path.dirname(os.path.abspath(__file__))
        chapters = sys.argv[2] if len(sys.argv) > 2 else os.path.join(here, "..", "..", "PlaygroundBook", "Chapters")
        sys.exit(check(chapters) if mode == "check" else sync(chapters))
    out = sys.argv[2]
    if mode == "pages" and os.path.abspath(out).rstrip("/").endswith("PlaygroundBook/Chapters"):
        sys.exit("chain.py pages writes TEST pages (a one-line prose card); point it at a scratch folder, never the book's Chapters")
    pairs = chain()
    for (slug, case, chapter, folder, title), (start, done) in zip(PAGES, pairs):
        if mode == "dump":
            d = os.path.join(out, slug)
            os.makedirs(d, exist_ok=True)
            open(os.path.join(d, "starter.swift"), "w").write(start.text())
            open(os.path.join(d, "solution.swift"), "w").write(done.text())
        elif mode == "pages":
            d = os.path.join(out, chapter + ".playgroundchapter", "Pages", folder + ".playgroundpage")
            os.makedirs(d, exist_ok=True)
            page = HIDDEN % case
            if done.text() != start.text():
                page += "// MARK: - Solution\n" + commented(done.text())
            stuck = "" if case == "design" else "\n\n **Your tools:** test.\n\n " + stuck_line(slug)
            page += ("//#-end-hidden-code\n/*:\n # " + title + "\n Test page (generated by chain.py).\n\n ## Your turn\n - test."
                     + stuck + "\n */\n\n" + start.text())
            open(os.path.join(d, "main.swift"), "w").write(page)
    if mode == "pages":
        d = os.path.join(out, "Chapter16.playgroundchapter", "Pages", "README.playgroundpage")
        os.makedirs(d, exist_ok=True)
        open(os.path.join(d, "main.swift"), "w").write("/*:\n # README\n */\n")
        plist = ('<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
                 '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n%s</dict>\n</plist>\n')
        for chapter, (part, hints) in PARTS.items():
            folders = [p[3] for p in PAGES if p[2] == chapter] + [hints or "README"]
            if hints:
                d = os.path.join(out, chapter + ".playgroundchapter", "Pages", hints + ".playgroundpage")
                os.makedirs(d, exist_ok=True)
                card = "/*:\n # " + hints_title(chapter) + "\n Test page (generated by chain.py).\n"
                for p in PAGES:
                    if p[2] == chapter:
                        card += "\n ## " + p[4] + "\n **Hint 1:** test.\n\n **Hint 2:** test.\n\n **Hint 3:** test.\n"
                open(os.path.join(d, "main.swift"), "w").write(card + " */\n")
                open(os.path.join(d, "Manifest.plist"), "w").write(plist % (
                    "\t<key>Name</key>\n\t<string>%s</string>\n\t<key>LiveViewEdgeToEdge</key>\n\t<false/>\n"
                    "\t<key>LiveViewMode</key>\n\t<string>HiddenByDefault</string>\n" % hints_title(chapter)))
            open(os.path.join(out, chapter + ".playgroundchapter", "Manifest.plist"), "w").write(plist % (
                "\t<key>Name</key>\n\t<string>%s</string>\n\t<key>Pages</key>\n\t<array>\n%s\t</array>\n" % (
                    part, "".join("\t\t<string>%s.playgroundpage</string>\n" % f for f in folders))))


if __name__ == "__main__":
    main()
