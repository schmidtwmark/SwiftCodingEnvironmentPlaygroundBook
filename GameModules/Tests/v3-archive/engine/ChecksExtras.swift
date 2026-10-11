//
//  ChecksExtras.swift  (GameAPI: the checks of the Extra pages)
//
//  Extra pages play the finished game of pages 1-10 with their built-in scripts, so a drive here
//  can walk, collect coins and get hurt without any student code; the checks look only at the
//  scripts the page is about.
//
//  Part 1 Extras: Sounds, Sparkles, Backgrounds, Boing!, Hero Moves, Stopwatch, Locked Flag.
//  Part 2 Extras: Death Counter, Lives and Game Over, Star Power, Fireballs, Level 2.
//
//  Sounds, bursts and shakes are read from the test drive's effect log, never from the speaker,
//  so a muted iPad passes exactly the same way.
//

import Foundation

extension Checks {
    // ---------- Extra: Stopwatch ----------
    static let stopwatchLine = "game.showText(\"⏱ \" + String(game.timer / 60))"

    static let stopwatch: [Check] = [
        Check(title: "The timer counts frames") { scripts in
            game.timer = 0
            let t = TestDrive(still, scripts, game: true)
            var previous = game.timer, wentDown = false
            t.run(125) { _ in
                if game.timer < previous { wentDown = true }
                previous = game.timer
            }
            let counted = game.timer
            if counted == 125 && !wentDown { return nil }
            if counted == 0 && t.ranBuiltIn(.updateGame) { return missing(.updateGame) }
            if wentDown { return "game.timer went back down. Only game over should start it over: count with `game.timer += 1`, and don't set it back to 0." }
            if counted == 0 { return "game.timer never changes. In updateGame, count frames: `game.timer += 1`." }
            if counted == 250 { return "Your timer counts 2 every frame. Is `game.timer += 1` in your code twice? Keep just one." }
            return "In 125 frames your timer counted \(counted). Count 1 every frame: `game.timer += 1` in updateGame, with no if around it."
        },
        Check(title: "The stopwatch shows seconds") { scripts in
            game.score = 0
            let t = TestDrive(still, scripts, game: true)
            t.run(1)
            // 125 frames is 2 seconds; 3605 frames is 60. (Either side of the count line gives the
            // same number of seconds there.)
            var right = 0, frames = 0, showsFrames = false
            for start in [125, 3590] {
                game.timer = start
                let run = start == 125 ? 1 : 15
                t.run(run)
                let seconds = game.timer / 60
                frames += 1
                if t.shows(seconds, inFrame: t.world.frame) { right += 1 }
                if t.shows(game.timer, inFrame: t.world.frame) || t.shows(game.timer - 1, inFrame: t.world.frame) { showsFrames = true }
            }
            if right == frames { return nil }
            if t.ranBuiltIn(.updateGame) { return missing(.updateGame) }
            if showsFrames { return "Your stopwatch shows frames, not seconds. 60 frames is 1 second, so divide by 60: `String(game.timer / 60)`." }
            return "Show the seconds every frame, in updateGame: `\(stopwatchLine)`"
        },
    ]

    // ---------- Extra: Locked Flag ----------
    static let flagFirst = """
    ..........
    .P.F.o.o..
    ##########
    """
    static let flagLast = """
    ..........
    .P.o.o.F..
    ##########
    """
    static let coinsLeftLine = "game.showMessage(\"🪙 \" + String(game.coinsLeft) + \" coins left!\")"

    /// Walks onto the 🚩 with 2 coins still in the level, and stops there.
    static func flagWithCoinsLeft(_ scripts: Scripts) -> TestDrive {
        let t = TestDrive(flagFirst, scripts)
        t.run(20, hold: [.right])
        t.run(10)
        return t
    }

    static let lockedFlag: [Check] = [
        Check(title: "The 🚩 waits for every coin") { scripts in
            let early = flagWithCoinsLeft(scripts)
            let builtIn = early.ranBuiltIn(.playerTouchedFlag)
            let touched = early.world.flagReached
            if early.wins > 0 {
                if builtIn { return "Your 🚩 still wins right away. " + missing(.playerTouchedFlag) }
                return "Your 🚩 wins even with coins left. Win only when no coins are left: `if game.coinsLeft == 0 { game.win() }`."
            }
            if !touched { return "The test never reached the 🚩. Walking is built in on this page: if you copied updatePlayer in, make sure ▶ still walks right." }
            let late = TestDrive(flagLast, scripts)
            late.run(60, hold: [.right])
            if late.wins > 0 { return nil }
            return "Your 🚩 never lets you win, even with every coin collected. When `game.coinsLeft == 0`, call `game.win()`."
        },
        Check(title: "The 🚩 says how many coins are left") { scripts in
            let t = flagWithCoinsLeft(scripts)
            if t.messaged(2) { return nil }
            if t.ranBuiltIn(.playerTouchedFlag) { return missing(.playerTouchedFlag) }
            if t.messages.isEmpty { return "Touching the 🚩 with coins left shows nothing. In the else, add `\(coinsLeftLine)`" }
            return "Your message doesn't say how many coins are left. Join the number to it: `\(coinsLeftLine)`"
        },
    ]

    // ---------- Extra: Death Counter ----------
    static let crabAhead = """
    ..............
    .P..........c.
    ##############
    """
    static let deathsLine = "game.showText(\"💥 \" + String(game.deaths))"

    /// Three ouches: walking into a crab, then two forced player.hurt()s 70 frames apart. Returns
    /// game.deaths after frame 1 (before any ouch) and what each ouch added.
    static func threeOuches(_ scripts: Scripts) -> (firstFrame: Int, added: [Int], builtIn: Bool) {
        let start = game.deaths
        let t = TestDrive(crabAhead, scripts)
        t.run(1)
        let firstFrame = game.deaths - start
        var added: [Int] = []
        var before = game.deaths
        var n = 0
        while t.world.hurts == 0 && n < 150 { t.run(1, hold: [.right]); n += 1 }
        t.run(70)
        added.append(game.deaths - before)
        for _ in 0..<2 {
            before = game.deaths
            t.world.hurt()
            t.run(70)
            added.append(game.deaths - before)
        }
        return (firstFrame, added, t.ranBuiltIn(.playerGotHurt))
    }

    static let deathCounter: [Check] = [
        Check(title: "Every ouch counts once") { scripts in
            let o = threeOuches(scripts)
            if o.firstFrame != 0 { return "game.deaths went up before any ouch, because startPlayer runs when the level starts too. Count in playerGotHurt: `game.deaths += 1`." }
            if o.added == [1, 1, 1] { return nil }
            let total = o.added.reduce(0, +)
            if total == 0 && o.builtIn { return missing(.playerGotHurt) }
            // One forced ouch with game.deaths at 5: `= 1` makes 1.
            game.deaths = 5
            let probe = TestDrive(still, scripts)
            probe.run(1)
            probe.world.hurt()
            probe.run(2)
            if game.deaths == 1 { return "Your count is stuck at 1: `game.deaths = 1` sets it to 1 every time. Use += to add 1: `game.deaths += 1`." }
            if total == 0 { return "Your ouches didn't count. In playerGotHurt, add `game.deaths += 1`." }
            if o.added[0] > 0 && o.added[1] == 0 && o.added[2] == 0 {
                return "Only walking into an enemy counted. playerTouchedEnemy runs only for enemies; playerGotHurt runs once for every kind of ouch. Put `game.deaths += 1` in playerGotHurt."
            }
            if o.added.allSatisfy({ $0 == 2 }) { return "Every ouch counted 2. Is `game.deaths += 1` in your code twice? Keep one, in playerGotHurt." }
            if o.added[0] > o.added[1] { return "Walking into an enemy counted more than once, because your playerTouchedEnemy counts too. Count only in playerGotHurt." }
            return "Every ouch should add exactly 1: `game.deaths += 1` in playerGotHurt."
        },
        Check(title: "Your 💥 count shows on the screen") { scripts in
            let s = showsNumber(scripts, 7, 42) { game.deaths = $0 }
            return showHint(s, number: "game.deaths", line: deathsLine)
        },
    ]

    // ---------- Extra: Lives and Game Over ----------
    static let spikeStep = """
    .......
    .P^....
    #######
    """
    static let livesLine = "game.showText(\"❤️ \" + String(game.lives))"

    /// Walks into the spikes: one ouch in the middle of a frame, like a real one. (The player
    /// blinks for 60 frames after an ouch, so wait at least that long before the next.)
    static func walkIntoSpikes(_ t: TestDrive) {
        let before = t.world.hurts
        var n = 0
        while t.world.hurts == before && n < 30 { t.run(1, hold: [.right]); n += 1 }
    }

    static let lives: [Check] = [
        Check(title: "An ouch takes one life") { scripts in
            let t = TestDrive(spikeStep, scripts, game: true)
            t.run(2)
            let start = game.lives
            if start <= 0 {
                if t.ranBuiltIn(.startGame) { return missing(.startGame) }
                return "game.lives is \(start) when the game starts. In startGame, set `game.lives = 3`."
            }
            walkIntoSpikes(t)
            var lowest = game.lives
            t.run(40) { _ in lowest = min(lowest, game.lives) }
            let after = game.lives
            var stayed = true
            t.run(30) { _ in if game.lives != after { stayed = false } }
            if after == start - 1 && stayed { return nil }
            // Set in an update script? Change it between frames and see if it comes back.
            let probe = TestDrive(still, scripts, game: true)
            probe.run(2)
            game.lives = start + 4
            probe.run(1)
            let comesBack = game.lives == start
            if after == start && lowest < start {
                if comesBack { return "game.lives goes back to \(start) every frame, because it's set in an update script. Set it once, in startGame: `game.lives = 3`." }
                return "Your lives go back to \(start) after every ouch, because startPlayer runs after every ouch. Set them in startGame, which runs only when the game starts: `game.lives = 3`."
            }
            if comesBack { return "game.lives goes back to \(start) every frame, because it's set in an update script. Set it once, in startGame: `game.lives = 3`." }
            if after == start { return "An ouch didn't take a life. In playerGotHurt, take one away: `game.lives -= 1`." }
            if after == start - 2 { return "One ouch took 2 lives. Is `game.lives -= 1` in your code twice? Keep one, in playerGotHurt." }
            if after > start { return "An ouch gave you a life! Take one away: `game.lives -= 1`." }
            return "One ouch should take exactly one life: `game.lives -= 1` in playerGotHurt."
        },
        Check(title: "No lives left: game over") { scripts in
            let t = TestDrive(spikeStep, scripts, game: true)
            t.run(2)
            var livesAtLose: Int? = nil
            var ouches = 0
            while ouches < 12 && t.loses == 0 {
                walkIntoSpikes(t)
                ouches += 1
                if t.loses > 0 { livesAtLose = game.lives; break }
                t.run(62) { _ in if t.loses > 0 && livesAtLose == nil { livesAtLose = game.lives } }
            }
            guard let left = livesAtLose else {
                return "The game kept going with no lives left. In playerGotHurt, after taking a life: `if game.lives == 0 { game.lose() }`."
            }
            if left == 0 { return nil }
            if left > 0 { return "Game over came while you still had \(left) \(left == 1 ? "life" : "lives"). Call `game.lose()` only when `game.lives == 0`." }
            return "Game over came too late, after your lives went below 0. Use `if game.lives == 0 { game.lose() }`."
        },
        Check(title: "Your ❤️ show on the screen") { scripts in
            // 4, then 7 lives: a number, or a row of that many hearts (the Try it).
            let t = TestDrive(still, scripts, game: true)
            t.run(1)
            var right = 0, frames = 0
            var s = Shown()
            for (value, first) in [(4, true), (7, false)] {
                game.lives = value
                t.run(3) { w in
                    frames += 1
                    let texts = t.shown(inFrame: w.frame)
                    if t.shows(value, inFrame: w.frame) || texts.contains(where: { hearts(in: $0) == value }) { right += 1 }
                    for text in texts {
                        s.anyText = true
                        if text.contains("game.") { s.codeInQuotes = true }
                        if first { s.firstTexts.insert(text) } else { s.secondTexts.insert(text) }
                    }
                }
            }
            s.frames = frames
            s.framesRight = right
            s.builtIn = t.ranBuiltIn(.updateGame)
            return showHint(s, number: "game.lives", line: livesLine)
        },
    ]

    /// How many heart emoji a text has (❤️ 💖 💚 ... ♥️).
    static func hearts(in text: String) -> Int {
        let heartScalars: Set<UInt32> = [0x2764, 0x2665, 0x1F5A4, 0x1F90D, 0x1F90E, 0x1F9E1, 0x1FA75, 0x1FA76, 0x1FA77]
        return text.filter { ch in
            ch.unicodeScalars.contains { heartScalars.contains($0.value) || (0x1F493...0x1F49F).contains($0.value) }
        }.count
    }
}

// MARK: - Part 1 Extras: Sounds, Sparkles, Backgrounds, Boing!, Hero Moves

extension Checks {
    // ---------- Extra: Sounds ----------
    static let coinSoundLine = "game.playSound(.coin)"
    static let jumpSoundLine = "game.playSound(.jump)"

    /// Holds ▲ for 150 frames on the room map: the takeoff frames and the sounds. Then 60 frames
    /// with no button on a fresh drive: the sounds played while standing still.
    static func jumpLog(_ scripts: Scripts, bursts: Bool) -> (takeoffs: [Int], hits: [Int], idle: Int, builtIn: Bool) {
        let t = TestDrive(room, scripts)
        t.run(10)
        t.run(150, hold: [.up])
        let takeoffs = t.world.takeoffFrames
        let hits = bursts ? t.bursts(by: player) : t.sounds.map { $0.frame }
        let builtIn = t.ranBuiltIn(.updatePlayer)
        let idle = TestDrive(room, scripts)
        idle.run(60)
        let idleCount = bursts ? idle.bursts(by: player).count : idle.sounds.count
        return (takeoffs, hits, idleCount, builtIn)
    }

    static let sounds: [Check] = [
        Check(title: "A coin plays a sound, once") { scripts in
            let t = TestDrive(coinRow, scripts)
            t.run(100, hold: [.right])
            let touched = Set(t.world.coinTouchFrames)
            let played = t.sounds.map { $0.frame }
            let inCoinFrames = played.filter { touched.contains($0) }.count
            let coins = t.world.coins.count
            if played.count == coins && inCoinFrames == coins { return nil }
            if played.isEmpty {
                if t.ranBuiltIn(.playerTouchedCoin) { return missing(.playerTouchedCoin) }
                return "Grabbing a coin is silent. In playerTouchedCoin, add `\(coinSoundLine)` above `coin.remove()`."
            }
            if played.count >= 20 && inCoinFrames * 2 < played.count {
                return "Your sound plays 60 times a second, because it's in an update script. Put `\(coinSoundLine)` inside playerTouchedCoin, which runs when you touch a coin."
            }
            if inCoinFrames > coins {
                return "A coin played its sound again and again, because a coin keeps touching you until it's removed. Keep `coin.remove()` in playerTouchedCoin."
            }
            if inCoinFrames < coins && inCoinFrames == played.count {
                return "Only some coins played a sound. Play it for every coin: `\(coinSoundLine)` in playerTouchedCoin, with no if around it."
            }
            return "Each coin should play its sound once, when you touch it: `\(coinSoundLine)` in playerTouchedCoin."
        },
        Check(title: "A jump plays a sound, once per jump") { scripts in
            let j = jumpLog(scripts, bursts: false)
            if j.builtIn { return missing(.updatePlayer) }
            let takeoffs = Set(j.takeoffs)
            let onTakeoff = j.hits.filter { takeoffs.contains($0) }.count
            if j.idle > 0 {
                return "A sound plays while you stand still, so it's in your update script with no if around it. Sounds go inside an if or an event: put `\(jumpSoundLine)` under `player.speedY = 18`."
            }
            if j.hits.count == j.takeoffs.count && onTakeoff == j.takeoffs.count && !j.takeoffs.isEmpty { return nil }
            if j.takeoffs.isEmpty { return "Holding ▲ didn't jump. Keep the jump code as it is on this page." }
            if j.hits.count > j.takeoffs.count + 5 {
                return "Your jump sound plays every frame ▲ is held, so it buzzes. Move it inside `if player.isOnGround() { }`, under `player.speedY = 18`."
            }
            if j.hits.isEmpty { return "Jumping is silent. Add `\(jumpSoundLine)` under `player.speedY = 18`." }
            return "Each jump should play its sound once, when you leave the ground: put `\(jumpSoundLine)` right under `player.speedY = 18`."
        },
    ]

    // ---------- Extra: Sparkles ----------
    static let coinBurstLine = "coin.burst(\"✨\")"
    static let dustLine = "player.burst(\"💨\", count: 6, speed: 2)"

    static let sparkles: [Check] = [
        Check(title: "Grabbing a coin makes sparkles there") { scripts in
            let t = TestDrive(coinRow, scripts)
            t.run(100, hold: [.right])
            let touched = Set(t.world.coinTouchFrames)
            let coins = t.world.coins
            let perCoin = coins.map { t.bursts(by: $0) }
            // Each coin sparkles in the one frame it is touched (two bursts in that frame, like a
            // ✨ and a "+1", are fine).
            if perCoin.allSatisfy({ !$0.isEmpty && Set($0).count == 1 && touched.contains($0[0]) }) { return nil }
            let all = t.allBursts
            let fromCoins = perCoin.reduce(0) { $0 + $1.count }
            let fromPlayer = t.bursts(by: player)
            if fromCoins == 0 {
                if t.ranBuiltIn(.playerTouchedCoin) { return missing(.playerTouchedCoin) }
                if fromPlayer.count >= 20 { return "A burst every frame is a trail! For a coin's sparkles, put `\(coinBurstLine)` in playerTouchedCoin." }
                if !fromPlayer.isEmpty && fromPlayer.contains(where: { touched.contains($0) }) {
                    return "Your sparkles come out of the player. Inside playerTouchedCoin, `coin` is the coin you touched: `\(coinBurstLine)`."
                }
                if all.isEmpty { return "Grabbing a coin makes no sparkles. In playerTouchedCoin, add `\(coinBurstLine)` above `coin.remove()`." }
                return "Make the sparkles at the coin: `\(coinBurstLine)` in playerTouchedCoin."
            }
            if perCoin.contains(where: { Set($0).count > 1 }) {
                return "A coin made sparkles again and again, because it keeps touching you until it's removed. Keep `coin.remove()` in playerTouchedCoin."
            }
            return "Every coin should sparkle once, when you touch it: `\(coinBurstLine)` in playerTouchedCoin, with no if around it."
        },
        Check(title: "A jump kicks up dust") { scripts in
            let j = jumpLog(scripts, bursts: true)
            if j.builtIn { return missing(.updatePlayer) }
            let takeoffs = Set(j.takeoffs)
            let onTakeoff = j.hits.filter { takeoffs.contains($0) }.count
            if j.idle > 0 {
                return "Dust comes out while you stand still, so your burst is in updatePlayer with no if around it. Put `\(dustLine)` under `player.speedY = 18`."
            }
            if j.hits.count == j.takeoffs.count && onTakeoff == j.takeoffs.count && !j.takeoffs.isEmpty { return nil }
            if j.takeoffs.isEmpty { return "Holding ▲ didn't jump. Keep the jump code as it is on this page." }
            if j.hits.count > j.takeoffs.count + 5 {
                return "Dust comes out every frame ▲ is held. Move the burst inside `if player.isOnGround() { }`, under `player.speedY = 18`."
            }
            if j.hits.isEmpty { return "Jumping makes no dust. Add `\(dustLine)` under `player.speedY = 18`." }
            return "Each jump should make one puff of dust, when you leave the ground: put `\(dustLine)` right under `player.speedY = 18`."
        },
    ]

    // ---------- Extra: Backgrounds ----------
    static let horizonLine = "game.horizonColor = .hex(\"ffd194\")"
    static let treeLayerLine = "game.addLayer(\"🌲 🌳🌲   🌲🌲 \", y: 64, size: 100, distance: 2)"

    static let backgrounds: [Check] = [
        Check(title: "The sky fades") { _ in
            guard let horizon = game.horizonSetting else {
                return "The sky is one color. Under the skyColor line, add `\(horizonLine)`."
            }
            if horizon == game.skyColor {
                return "Your horizonColor is the same as skyColor, so the sky doesn't fade. Pick another color for one of them."
            }
            return nil
        },
        Check(title: "Two layers at different distances") { _ in
            let layers = game.layers
            let distances = Set(layers.map { $0.distance })
            if layers.count >= 2 && distances.count >= 2 { return nil }
            if layers.isEmpty { return "There are no layers of your own. Add one: `\(treeLayerLine)`." }
            if layers.count == 1 { return "One layer can't show depth. Add a closer layer: `\(treeLayerLine)`." }
            let d = layers[0].distance
            return "Your layers all have distance \(d), so they scroll together. Give the closer one a smaller distance, like `distance: 2`."
        },
    ]

    // ---------- Extra: Boing! ----------
    static let springWall = """
    ...........
    ...........
    ...........
    ...........
    ...........
    .....#.....
    .....#.....
    .....#.....
    .P.s.#.....
    ###########
    """
    static let springLine = "player.speedY = 25"

    static let boing: [Check] = [
        Check(title: "🍄 bounces you over a tall wall") { scripts in
            let t = TestDrive(springWall, scripts)
            let start = player.y
            var highest = start, lowestSpeed = 0, firstLaunch = 0, grows = false
            var previousSpeed = 0
            t.run(120, hold: [.right]) { _ in
                highest = max(highest, player.y)
                lowestSpeed = min(lowestSpeed, player.speedY)
                if firstLaunch == 0 && player.speedY > previousSpeed + 2 && player.speedY > 0 { firstLaunch = player.speedY }
                else if firstLaunch > 0 && player.speedY > firstLaunch + 1 { grows = true }
                previousSpeed = player.speedY
            }
            let rise = highest - start
            if t.ranBuiltIn(.playerTouchedSpring) { return missing(.playerTouchedSpring) }
            if grows { return "You shot into space! += adds 25 again every frame you touch the 🍄. Use =: `\(springLine)`." }
            if rise >= 250 && player.x > 5 * 64 { return nil }
            if rise >= 250 { return "You bounced up, but not over the wall. Keep holding ▶ while you bounce." }
            if rise <= 4 && lowestSpeed < -2 { return "The 🍄 pushed you down. Up is positive: `\(springLine)`." }
            if rise <= 4 { return "The 🍄 didn't bounce you. In playerTouchedSpring, set your speed: `\(springLine)`." }
            return "That's only a jump: you rose \(rise) points, and the wall is 256. Use a bigger number: `\(springLine)`."
        },
    ]

    // ---------- Extra: Hero Moves ----------
    static let looksLine = "if player.isOnGround() { player.emoji = \"🧍\" } else { player.emoji = \"🤸\" }"

    static let heroMoves: [Check] = [
        Check(title: "You look different in the air") { scripts in
            let t = TestDrive(room, scripts)
            t.run(10)
            let standing = player.emoji
            var air = 0, airDifferent = 0, landed = -1, frame = 0
            t.run(3, hold: [.up])
            t.run(100) { _ in
                frame += 1
                if !player.isOnGround() {
                    air += 1
                    if player.emoji != standing { airDifferent += 1 }
                } else if landed < 0 && air > 0 {
                    landed = frame
                }
            }
            if t.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if air == 0 { return "Pressing ▲ didn't jump. Keep the jump code as it is on this page." }
            t.run(10)
            let backAfterLanding = player.emoji == standing
            if airDifferent * 10 >= air * 6 && backAfterLanding { return nil }
            if airDifferent * 10 < air * 6 {
                return "Your hero looks the same in the air. At the bottom of updatePlayer, give it an air look: `\(looksLine)`."
            }
            return "After landing, your hero keeps its air look. Inside `if player.isOnGround() { }`, set the standing look again, like `player.emoji = \"🧍\"`."
        },
        Check(title: "You look different when you walk") { scripts in
            let t = TestDrive(flat, scripts)
            t.run(10)
            let standing = player.emoji
            var different = 0
            t.run(40, hold: [.right]) { _ in if player.emoji != standing { different += 1 } }
            var back = false
            t.run(10) { _ in if player.emoji == standing { back = true } }
            if t.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if different * 10 >= 40 * 4 && back { return nil }
            if different * 10 < 40 * 4 {
                return "Walking looks the same as standing. Inside `if player.isOnGround() { }`: `if player.speedX == 0 { player.emoji = \"🧍\" } else { player.emoji = \"🏃\" }`."
            }
            return "When you stop, your hero keeps its walking look. Set the standing look when `player.speedX == 0`."
        },
    ]
}

// MARK: - Part 2 Extras: Star Power, Fireballs, Level 2

extension Checks {
    // ---------- Extra: Star Power ----------
    static let starCrabs = """
    ...............
    .P.*...ccc.....
    ###############
    """
    static let starThenCrab: String = ".........\n.P*" + String(repeating: ".", count: 36) + "c.\n" + String(repeating: "#", count: 41)
    static let starTimerLine = "player.timer = 300"
    static let starBranch = "if player.timer > 0 { enemy.remove() } else"

    static let starPower: [Check] = [
        Check(title: "A ⭐ lets you plow through enemies") { scripts in
            let t = TestDrive(starCrabs, scripts)
            var highestTimer = 0
            t.run(120, hold: [.right]) { _ in highestTimer = max(highestTimer, player.timer) }
            let removed = t.crabs.filter { $0.removed }.count
            if removed == 3 && t.world.hurts == 0 { return nil }
            if t.ranBuiltIn(.playerTouchedStar) { return missing(.playerTouchedStar) }
            if highestTimer <= 0 { return "Touching the ⭐ didn't start star power. In playerTouchedStar, add `\(starTimerLine)`." }
            if t.ranBuiltIn(.playerTouchedEnemy) { return missing(.playerTouchedEnemy) }
            if t.world.hurts > 0 {
                return "You got hurt even with star power, because `player.hurt()` runs first. In playerTouchedEnemy, type `\(starBranch)` right in front of the `if` that's already there."
            }
            return "With star power, an enemy you touch should disappear. In playerTouchedEnemy, type `\(starBranch)` right in front of the `if` that's already there."
        },
        Check(title: "Star power runs out") { scripts in
            let t = TestDrive(starThenCrab, scripts)
            t.run(8, hold: [.right])
            let afterStar = player.timer
            t.run(720)
            let afterWait = player.timer
            var n = 0
            while t.world.hurts == 0 && n < 300 && !t.crabs[0].removed { t.run(1, hold: [.right]); n += 1 }
            if t.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if afterStar <= 0 {
                if t.ranBuiltIn(.playerTouchedStar) { return missing(.playerTouchedStar) }
                return "Touching the ⭐ didn't start star power. In playerTouchedStar, add `\(starTimerLine)`."
            }
            if t.world.hurts > 0 && !t.crabs[0].removed { return nil }
            if afterWait > afterStar { return "Your star power counts up, so it never runs out. Count down: `player.timer -= 1`." }
            if afterWait == afterStar { return "Star power never runs out, because player.timer never changes. At the bottom of updatePlayer: `if player.timer > 0 { player.timer -= 1 }`." }
            return "12 seconds after the ⭐, an enemy should hurt you again. Count player.timer down to 0, and remove enemies only while `player.timer > 0`."
        },
        Check(title: "Without a ⭐, enemies still hurt") { scripts in
            let t = TestDrive(stompWalk, scripts)
            t.run(90, hold: [.right])
            if t.world.hurts > 0 && !t.crabs[0].removed { return nil }
            if t.crabs[0].removed { return "Without a ⭐, walking into an enemy squished it. Remove enemies only while `player.timer > 0`." }
            return "Without a ⭐, walking into an enemy should hurt: keep `else { player.hurt() }` at the end."
        },
    ]

    // ---------- Extra: Fireballs ----------
    static let fireLine = "game.spawn(.fireball, x: player.x, y: player.y, speedX: 12, speedY: 0)"
    static let crabFiveAhead = """
    .............
    .P.....c.....
    #############
    """

    /// Taps ▼ (after `before` frames holding `walk`, then 3 frames with no button) and follows the
    /// first fireball for `frames` frames: how far it got from the player, and how it moved.
    static func throwFire(_ scripts: Scripts, walk: [GameKey] = [], frames: Int = 10) -> (fireballs: Int, farthest: Int, dx: Int, builtIn: Bool) {
        let t = TestDrive(flat, scripts)
        t.run(6, hold: walk)
        t.run(3)
        var seen: [Fireball] = []
        var farthest = 0
        t.tap(.down, then: frames) { _ in
            for f in t.fireballs where !seen.contains(where: { $0 === f }) { seen.append(f) }
            if let f = seen.first { farthest = max(farthest, abs(f.x - player.x)) }
        }
        let dx = seen.first.map { $0.x - $0.startX } ?? 0
        return (seen.count, farthest, dx, t.ranBuiltIn(.updatePlayer))
    }

    static let fireballs: [Check] = [
        Check(title: "▼ throws a 🔥") { scripts in
            let f = throwFire(scripts)
            if f.fireballs > 0 && f.farthest >= 60 { return nil }
            if f.builtIn { return missing(.updatePlayer) }
            if f.fireballs == 0 { return "Pressing ▼ didn't throw anything. At the bottom of updatePlayer: `if justPressed(.down) { \(fireLine) }`" }
            return "Your 🔥 doesn't fly away. Give it a speed: `speedX: 12`."
        },
        Check(title: "The 🔥 flies the way you face") { scripts in
            let right = throwFire(scripts, walk: [.right]), left = throwFire(scripts, walk: [.left])
            if right.dx > 0 && left.dx < 0 { return nil }
            if left.builtIn { return missing(.updatePlayer) }
            if left.fireballs == 0 || right.fireballs == 0 { return "Pressing ▼ didn't throw anything. At the bottom of updatePlayer: `if justPressed(.down) { }`" }
            if left.dx >= 0 { return "Facing left, your 🔥 still flies right. If `player.facingRight()` is false, throw it with `speedX: -12`." }
            return "Facing right, your 🔥 should fly right: `speedX: 12` when `player.facingRight()` is true."
        },
        Check(title: "Holding ▼ throws just one 🔥") { scripts in
            let t = TestDrive(flat, scripts)
            t.run(5)
            var seen: [Fireball] = []
            t.run(30, hold: [.down]) { _ in
                for f in t.fireballs where !seen.contains(where: { $0 === f }) { seen.append(f) }
            }
            if seen.count >= 1 && seen.count <= 2 { return nil }
            if t.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if seen.isEmpty { return "Pressing ▼ didn't throw anything. At the bottom of updatePlayer: `if justPressed(.down) { }`" }
            return "Holding ▼ threw \(seen.count) fireballs: isPressed is true 60 times a second. Use `justPressed(.down)`, which is true only on the first frame of a press."
        },
        Check(title: "A 🔥 knocks out an enemy") { scripts in
            let t = TestDrive(crabFiveAhead, scripts)
            t.run(3)
            var thrown = 0
            var flyingAfterHit: Int? = nil
            let crab = t.crabs[0]
            t.tap(.down, then: 70) { _ in
                thrown = max(thrown, t.fireballs.count)
                if crab.removed && flyingAfterHit == nil { flyingAfterHit = t.fireballs.count }
            }
            let crabGone = crab.removed
            if crabGone && flyingAfterHit == 0 && t.world.hurts == 0 { return nil }
            if t.ranBuiltIn(.fireballTouchedEnemy) { return missing(.fireballTouchedEnemy) }
            if thrown == 0 && !crabGone { return "Pressing ▼ didn't throw anything. At the bottom of updatePlayer: `if justPressed(.down) { }`" }
            if !crabGone { return "Your 🔥 flew through the crab. In fireballTouchedEnemy, add `enemy.remove()`." }
            return "The 🔥 keeps flying after it hits. In fireballTouchedEnemy, add `fireball.remove()` too."
        },
    ]

    // ---------- Extra: Level 2 ----------
    static let flagRun = """
    ..........
    .P....F...
    ##########
    """

    /// How many squares of two maps differ (a longer or shorter row counts its extra letters).
    static func lettersChanged(_ a: String, _ b: String) -> Int {
        func rows(_ m: String) -> [[Character]] {
            m.replacingOccurrences(of: "\r", with: "").split(separator: "\n", omittingEmptySubsequences: false)
                .map { Array($0.trimmingCharacters(in: .whitespaces)) }
                .filter { !$0.isEmpty }
        }
        let ra = rows(a), rb = rows(b)
        var changed = 0
        for i in 0..<max(ra.count, rb.count) {
            let x = i < ra.count ? ra[i] : [], y = i < rb.count ? rb[i] : []
            for j in 0..<max(x.count, y.count) where (j < x.count ? x[j] : " ") != (j < y.count ? y[j] : " ") {
                changed += 1
            }
        }
        return changed
    }

    static let level2: [Check] = [
        Check(title: "Level 2 has a P and a 🚩, and it's yours") { _ in
            let map = game.level2
            if map.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "game.level2 is empty. Draw level 2 between the \"\"\" lines in Settings."
            }
            let parsed = parseMap(map)
            if let problem = parsed.problems.first { return "Level 2: " + problem }
            if lettersChanged(map, Levels.level2Starter) < 3 {
                return "Make level 2 your own: change at least 3 letters of its map (add a `c`, some `o`, or a wall)."
            }
            return nil
        },
        Check(title: "The 🚩 takes you to level 2") { scripts in
            let t = TestDrive(flagRun, scripts)
            t.run(60, hold: [.right])
            if t.nextLevels > 0 && t.wins == 0 { return nil }
            if t.wins > 0 { return "Touching the 🚩 still wins. In playerTouchedFlag, replace `game.win()` with `game.nextLevel()`." }
            if !t.world.flagReached { return "The test never reached the 🚩. Walking is built in on this page: if you copied updatePlayer in, make sure ▶ still walks right." }
            return "Touching the 🚩 does nothing. In playerTouchedFlag, call `game.nextLevel()`."
        },
    ]
}
