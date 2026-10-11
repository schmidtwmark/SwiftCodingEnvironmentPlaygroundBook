//
//  ChecksCore.swift  (GameAPI: the checks of lesson pages 1-9)
//
//  A test drive builds a tiny level, fakes the buttons, runs the same World.step() as the game,
//  and measures what happened. Checks use only engine objects and literal numbers. When a page's
//  function has a different first line from the one the engine looks for, the engine quietly uses
//  its built-in version; every check notices that and shows the exact first line instead.
//

import Foundation

enum Checks {
    /// The hint when the engine had to use built-in scripts: the page's function is missing, or its
    /// first line is not exactly the one the engine looks for (so Swift sees another function).
    static func missing(_ scripts: ScriptName...) -> String {
        if scripts.count == 1, let s = scripts.first {
            return "The engine can't find your \(s.name), so it uses the built-in one, which \(builtInDoes(s)). Its first line must be exactly `\(s.firstLine)`"
        }
        let names = scripts.map { $0.name }.joined(separator: " and ")
        let lines = scripts.map { "`\($0.firstLine)`" }.joined(separator: " and ")
        return "The engine can't find your \(names), so it uses the built-in ones, which \(builtInDoes(scripts[0])). Their first lines must be exactly \(lines)"
    }

    /// What the built-in version of a script does on this page.
    static func builtInDoes(_ script: ScriptName) -> String {
        let finished = Runtime.shared.info.builtIns == .finished
        switch script {
        case .playerTouchedEnemy: return finished ? "squishes an enemy you land on and hurts you otherwise" : "always hurts you"
        case .playerTouchedFlag: return "wins the game"
        case .playerGotHurt: return "only shows \"Ouch!\""
        case .updateGame: return finished ? "only shows the ⭐ score" : "does nothing"
        case .updatePlayer: return finished ? "walks, falls and jumps" : "does nothing"
        case .playerTouchedCoin: return finished ? "adds 1 to game.score" : "does nothing"
        default: return "does nothing"
        }
    }

    // ---------- 1. Walk ----------
    static let flat = """
    ..............
    ......P.......
    ##############
    """

    /// Holds `keys` for 30 frames: how far the player moved, whether its speed kept growing, and
    /// whether speedX was ever not 0 (it moved with speed, not by changing x).
    static func walkTest(_ scripts: Scripts, hold keys: [GameKey]) -> (moved: Int, speedingUp: Bool, hadSpeed: Bool, builtIn: Bool) {
        let t = TestDrive(flat, scripts)
        let start = player.x
        var speed10 = 0
        var hadSpeed = false
        t.run(30, hold: keys) { w in
            if w.frame == 10 { speed10 = player.speedX }
            if player.speedX != 0 { hadSpeed = true }
        }
        let speedingUp = speed10 != 0 && abs(player.speedX) > abs(speed10)
        return (player.x - start, speedingUp, hadSpeed, t.ranBuiltIn(.updatePlayer))
    }

    /// The hint for moving by changing x instead of speed (the same rule as the crab page).
    static func movedByX(_ speed: Int) -> String {
        "You moved by changing player.x. Move with your speed instead: `player.speedX = \(speed)`. The engine moves you by speedX every frame."
    }

    static let walk: [Check] = [
        Check(title: "▶ moves right") { scripts in
            let right = walkTest(scripts, hold: [.right])
            if right.builtIn { return missing(.updatePlayer) }
            if right.moved > 0 && !right.hadSpeed { return movedByX(6) }
            if right.moved > 0 && right.speedingUp { return "▶ makes you go faster and faster. Set the speed with =, not +=: `player.speedX = 6`." }
            if right.moved > 0 { return nil }
            if walkTest(scripts, hold: []).moved != 0 { return "You move even when no button is held. Set player.speedX only inside the if / else if / else." }
            if right.moved < 0 { return "▶ moved you LEFT. Check your ifs: ▶ is `isPressed(.right)`, and going right needs a positive speed: `player.speedX = 6`." }
            return "Holding ▶ didn't move you. Inside `if isPressed(.right) { }`, set `player.speedX = 6`. If an else below sets it back to 0, join them into one chain: `if ... { } else if ... { } else { }`."
        },
        Check(title: "◀ moves left") { scripts in
            let left = walkTest(scripts, hold: [.left])
            if left.builtIn { return missing(.updatePlayer) }
            if left.moved < 0 && !left.hadSpeed { return movedByX(-6) }
            if left.moved < 0 && left.speedingUp { return "◀ makes you go faster and faster. Set the speed with =, not -=: `player.speedX = -6`." }
            if left.moved < 0 { return nil }
            if left.moved > 0 { return "◀ moved you RIGHT. Going left needs a negative speed: `player.speedX = -6`." }
            return "Holding ◀ didn't move you. After the ▶ part, add `else if isPressed(.left) { player.speedX = -6 }`."
        },
        Check(title: "No button, no moving") { scripts in
            let idle = walkTest(scripts, hold: [])
            if idle.builtIn { return missing(.updatePlayer) }
            if idle.moved != 0 { return "You moved with no button held. The `else` runs when no button is held, so it should stop you: `else { player.speedX = 0 }`. Walk left in `else if isPressed(.left) { }`." }
            // Press a button, then let go: you should stop.
            for key in [GameKey.right, .left] {
                let t = TestDrive(flat, scripts)
                t.run(10, hold: [key])
                let letGo = player.x
                t.run(30)
                if player.x != letGo {
                    return "You keep sliding after you let go, because speedX stays the same until your code changes it. Add an else at the end: `else { player.speedX = 0 }`."
                }
            }
            return nil
        },
    ]

    // ---------- 2. Fall ----------
    static let tall: String = {
        var rows = ["..........", "....P....."]
        for _ in 0..<22 { rows.append("..........") }
        rows.append("##########")
        return rows.joined(separator: "\n")
    }()

    /// 20 frames in the air: how far the player went up (negative = down).
    static func drop(_ scripts: Scripts, hold keys: [GameKey]) -> (dy: Int, builtIn: Bool) {
        let t = TestDrive(tall, scripts)
        let start = player.y
        t.run(20, hold: keys)
        return (player.y - start, t.ranBuiltIn(.updatePlayer))
    }

    static let fall: [Check] = [
        Check(title: "You fall") { scripts in
            let idle = drop(scripts, hold: []), held = drop(scripts, hold: [.right])
            if idle.builtIn { return missing(.updatePlayer) }
            if idle.dy < 0 && held.dy < 0 { return nil }
            if idle.dy > 0 { return "You floated UP. Gravity pulls down, so use `player.speedY -= 1`." }
            if idle.dy < 0 { return "You only fall when no button is held. Move `player.speedY -= 1` below the whole if / else if / else, so it runs every frame." }
            if held.dy < 0 { return "You only fall while ▶ is held. Gravity goes at the bottom of updatePlayer, outside the ifs." }
            return "You didn't fall. Gravity changes your speed every frame: add `player.speedY -= 1` at the bottom of updatePlayer, outside the ifs."
        },
        Check(title: "You fall faster and faster") { scripts in
            let t = TestDrive(tall, scripts)
            var ys = [player.y]
            var hadSpeed = false
            t.run(10) { _ in
                ys.append(player.y)
                if player.speedY != 0 { hadSpeed = true }
            }
            let early = ys[0] - ys[5], late = ys[5] - ys[10]
            if late > early && early >= 0 { return nil }
            if early <= 0 && late <= 0 { return "You didn't fall. Add `player.speedY -= 1` at the bottom of updatePlayer." }
            if !hadSpeed { return "You fall at a steady speed, because you change player.y. Change your speed instead, with -= so it grows: `player.speedY -= 1`. The engine moves you by speedY every frame." }
            return "You fall at a steady speed, because your speed never changes. Gravity changes it every frame: use -=, as in `player.speedY -= 1` (not `player.speedY = -1`)."
        },
        Check(title: "You land and stop") { scripts in
            let t = TestDrive(tall, scripts)
            t.run(600)
            let landed = player.y
            var stayed = true
            t.run(30) { _ in if player.y != landed { stayed = false } }
            if player.isOnGround() && stayed { return nil }
            if player.y > 1000 { return "You went up and never came down. Gravity pulls down: use `player.speedY -= 1`." }
            return "You should end up standing on the floor. Do you change player.y anywhere else?"
        },
    ]

    // ---------- 3. Jump ----------
    static let room: String = {
        var rows: [String] = []
        for _ in 0..<12 { rows.append("............") }
        rows.append(".....P......")
        rows.append("############")
        return rows.joined(separator: "\n")
    }()

    static let jump: [Check] = [
        Check(title: "▲ jumps") { scripts in
            // First: with no button held you stay on the ground (catches isOnGround() in place of isPressed(.up)).
            let idle = TestDrive(room, scripts)
            var hopped = false
            idle.run(60) { _ in if !player.isOnGround() { hopped = true } }
            if idle.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if hopped { return "You jump even when ▲ isn't pressed. Put the jump inside `if isPressed(.up) { }`, with `if player.isOnGround() { }` inside that." }
            let t = TestDrive(room, scripts)
            t.run(10)
            let ground = player.y
            var highest = ground
            t.run(3, hold: [.up]) { _ in highest = max(highest, player.y) }
            t.run(90) { _ in highest = max(highest, player.y) }
            if highest - ground >= 40 { return nil }
            if highest > ground { return "That jump is tiny. Try a bigger number: `player.speedY = 18`." }
            return "Pressing ▲ didn't lift you. Inside `if isPressed(.up) { }`, check `if player.isOnGround() { }` and set `player.speedY = 18`."
        },
        Check(title: "Holding ▲ can't make you fly") { scripts in
            // First: tap ▲ and let go. You have to come back down.
            let tap = TestDrive(room, scripts)
            tap.run(10)
            tap.run(3, hold: [.up])
            var up = false, back = false
            tap.run(150) { _ in
                if !player.isOnGround() { up = true }
                if up && player.isOnGround() { back = true }
            }
            if tap.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if up && !back {
                return "You jumped and never came back down. Keep the gravity line `player.speedY -= 1` in updatePlayer."
            }
            // Then: hold ▲ the whole time.
            let t = TestDrive(room, scripts)
            t.run(10)
            var leftGround = false, landed = false
            t.run(300, hold: [.up]) { _ in
                if !player.isOnGround() { leftGround = true }
                if leftGround && player.isOnGround() { landed = true }
            }
            if landed { return nil }
            if !leftGround { return "Pressing ▲ didn't lift you." }
            return "Holding ▲ lets you fly! Only jump from the ground: put `if player.isOnGround() { }` around `player.speedY = 18`."
        },
    ]

    // ---------- 4. Coins ----------
    static let coinRow = """
    ..............
    .P...o.o.o....
    ##############
    """

    static let coins: [Check] = [
        Check(title: "A coin adds to game.score") { scripts in
            let t = TestDrive(coinRow, scripts)
            let start = game.score
            t.run(45, hold: [.right])
            if game.score > start { return nil }
            if t.ranBuiltIn(.playerTouchedCoin) { return missing(.playerTouchedCoin) }
            if t.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            return "Touching a coin didn't change the score. In playerTouchedCoin, add `game.score += 1`."
        },
        Check(title: "Each coin counts once and disappears") { scripts in
            let t = TestDrive(coinRow, scripts)
            let start = game.score
            t.run(100, hold: [.right])
            t.run(30)
            let gained = game.score - start
            let left = t.world.coins.filter { !$0.removed }.count
            if t.world.hurts > 0 { return "You got hurt! Inside playerTouchedCoin, `coin` is the coin you touched, so use `coin.remove()`, not `player.remove()`." }
            if gained > 0 && left == 0 { return nil }
            if t.ranBuiltIn(.playerTouchedCoin) { return missing(.playerTouchedCoin) }
            if gained == 0 && left == 0 { return "The coins disappear, but game.score doesn't go up. Add `game.score += 1` too." }
            if gained == 0 { return "Touching a coin didn't change the score. Add `game.score += 1`." }
            if left > 0 && gained == 3 { return "Each coin counted once, but it's still in the game, so the 🚩 stays locked. Add `coin.remove()`." }
            if left > 0 { return "3 coins gave you \(gained) points, because a coin keeps touching you every frame. Add `coin.remove()` so the coin disappears." }
            return "3 coins should add 3 to the score, but the score went up by \(gained). Add exactly 1 for each coin."
        },
    ]

    // ---------- 5. Show the Score ----------
    static let still = """
    ..........
    ....P.....
    ##########
    """
    static let scoreCoin = """
    ..........
    .P.o......
    ##########
    """

    /// The texts a number-showing check found: on how many of the frames each wanted number was in
    /// a shown text, and what else was shown.
    struct Shown {
        var framesRight = 0
        var frames = 0
        var anyText = false
        /// A shown text has the letters "game." in it (code inside quotes).
        var codeInQuotes = false
        /// The texts on the first value's frames, and on the second value's frames.
        var firstTexts: Set<String> = []
        var secondTexts: Set<String> = []
        var builtIn = false
    }

    /// Sets a game number to `a` and runs 3 frames, then to `b` and runs 3 more (after 1 frame for
    /// startGame), with the game's own scripts on. Every frame must show the number.
    static func showsNumber(_ scripts: Scripts, _ a: Int, _ b: Int, script: ScriptName = .updateGame, set: (Int) -> Void) -> Shown {
        let t = TestDrive(still, scripts, game: true)
        t.run(1)
        var s = Shown()
        for (value, first) in [(a, true), (b, false)] {
            set(value)
            t.run(3) { w in
                s.frames += 1
                if t.shows(value, inFrame: w.frame) { s.framesRight += 1 }
                for text in t.shown(inFrame: w.frame) {
                    s.anyText = true
                    if text.contains("game.") { s.codeInQuotes = true }
                    if first { s.firstTexts.insert(text) } else { s.secondTexts.insert(text) }
                }
            }
        }
        s.builtIn = t.ranBuiltIn(script)
        return s
    }

    /// The hints of a "your number shows on the screen" check (pages 5, Death Counter, Lives).
    static func showHint(_ s: Shown, number: String, line: String) -> String? {
        if s.framesRight == s.frames { return nil }
        if s.builtIn { return missing(.updateGame) }
        if s.codeInQuotes { return "Your text shows the letters \"\(number)\". Inside quotes, everything is just text. Put the number outside the quotes: `\(line)`" }
        if !s.anyText { return "Nothing shows up. In updateGame, add `\(line)`" }
        if s.framesRight > 0 { return "Your number shows on only some frames. updateGame runs every frame: show it there, with no if around it." }
        if !s.firstTexts.isEmpty && s.firstTexts == s.secondTexts { return "Your text stays the same when \(number) changes. Use `String(\(number))`, not a number you typed." }
        return "Your text shows a number, but not \(number). Use `String(\(number))`: `\(line)`"
    }

    static let scoreLine = "game.showText(\"⭐ \" + String(game.score))"

    static let score: [Check] = [
        Check(title: "The score shows on the screen") { scripts in
            let s = showsNumber(scripts, 38, 513) { game.score = $0 }
            return showHint(s, number: "game.score", line: scoreLine)
        },
        Check(title: "It stays on the screen") { scripts in
            // Walk into a coin: the score must be on the screen every frame, before and after.
            let t = TestDrive(scoreCoin, scripts, game: true)
            var shownFrames: [Int] = []
            var coinFrames: [Int] = []
            var lateFrames = 0
            var score = game.score
            t.run(40, hold: [.right]) { w in
                let before = score
                if game.score != score { coinFrames.append(w.frame); score = game.score }
                if t.shows(game.score, inFrame: w.frame) { shownFrames.append(w.frame) } else if before != score && t.shows(before, inFrame: w.frame) { lateFrames += 1 }
            }
            if shownFrames.count == 40 { return nil }
            if lateFrames > 0 && shownFrames.count + lateFrames == 40 {
                return "Your score is one frame late: it shows before the coin is counted. updateGame runs after every other script, so it sees the new score. Show it there."
            }
            let builtIn = t.ranBuiltIn(.updateGame)
            if shownFrames.isEmpty {
                if builtIn { return missing(.updateGame) }
                return "The score never shows. In updateGame, add `\(scoreLine)`"
            }
            if shownFrames.allSatisfy({ coinFrames.contains($0) }) {
                return "Your score shows only in the frame you touch a coin. showText lasts one frame. Put it in updateGame, which runs every frame."
            }
            if shownFrames == [1] {
                return "Your score shows only on the first frame. showText lasts one frame, and startGame runs once. Put it in updateGame, which runs every frame."
            }
            if builtIn { return missing(.updateGame) }
            return "Your score disappears on some frames. showText lasts one frame: show it every frame, in updateGame, with no if around it."
        },
    ]

    // ---------- 6. Crab Patrol ----------
    /// Boxes 4 and 7 squares wide, and the player shut in a pocket on the right.
    static let crabBoxes = """
    ################
    #..c.#....c..#P#
    ################
    """

    struct Patrol {
        var minX: Int, maxX: Int
        var turns = 0
        var midTurns = 0
        var firstDir = 0
        var lastDir = 0
        /// Its speedX was not 0 at some point (it moved with speed, not by changing x).
        var hadSpeed = false
        /// Its speedX at the end of the test drive.
        var endSpeed = 0
    }

    static func patrol(_ scripts: Scripts, frames: Int) -> (log: [Patrol], walls: [(Int, Int)], builtInStart: Bool, builtInUpdate: Bool) {
        let t = TestDrive(crabBoxes, scripts)
        let crabs = t.crabs
        // Where a crab's middle is when it touches each wall of its box.
        let walls = [(1 * 64 + 24, 5 * 64 - 24), (6 * 64 + 24, 13 * 64 - 24)]
        var log = crabs.map { Patrol(minX: $0.x, maxX: $0.x) }
        var previous = crabs.map { $0.x }
        t.run(frames) { _ in
            for (i, crab) in crabs.enumerated() where i < 2 {
                if crab.speedX != 0 { log[i].hadSpeed = true }
                log[i].endSpeed = crab.speedX
                let dx = crab.x - previous[i]
                previous[i] = crab.x
                log[i].minX = min(log[i].minX, crab.x)
                log[i].maxX = max(log[i].maxX, crab.x)
                guard dx != 0 else { continue }
                let dir = dx > 0 ? 1 : -1
                if log[i].firstDir == 0 { log[i].firstDir = dir }
                if log[i].lastDir != 0 && dir != log[i].lastDir {
                    log[i].turns += 1
                    let atWall = crab.x - dx <= walls[i].0 + 3 || crab.x - dx >= walls[i].1 - 3
                    if !atWall { log[i].midTurns += 1 }
                }
                log[i].lastDir = dir
            }
        }
        return (log, walls, t.ranBuiltIn(.startCrab), t.ranBuiltIn(.updateCrab))
    }

    static let wiggles = "A crab wiggles in place, because it flips its speed every frame. Only flip at a wall: put `crab.speedX = -crab.speedX` inside `if crab.facingWall() { }`."
    static let stoodStill = "A crab stood still. In startCrab, give it a speed: `crab.speedX = -2`. The engine moves it by speedX every frame."

    static let crab: [Check] = [
        Check(title: "Crabs walk") { scripts in
            let p = patrol(scripts, frames: 60)
            if p.builtInStart && p.builtInUpdate { return missing(.startCrab, .updateCrab) }
            for l in p.log where l.maxX - l.minX < 4 {
                if l.turns > 2 { return wiggles }
                if p.builtInStart { return missing(.startCrab) }
                return stoodStill
            }
            return nil
        },
        Check(title: "Each crab turns around at walls") { scripts in
            let p = patrol(scripts, frames: 900)   // speed 1 needs 664 frames to touch both walls
            func full(_ i: Int) -> Bool { p.log[i].minX <= p.walls[i].0 + 4 && p.log[i].maxX >= p.walls[i].1 - 4 }
            if p.log.indices.allSatisfy({ full($0) && p.log[$0].turns >= 2 && p.log[$0].midTurns == 0 }) { return nil }
            let moved = { (l: Patrol) in l.maxX - l.minX >= 4 }
            if p.log.contains(where: { $0.midTurns > 0 }) {
                return "A crab turned around in the middle of the floor. Each crab has its own speedX: flip it with `crab.speedX = -crab.speedX`, not with a variable every crab shares."
            }
            if p.log.contains(where: { moved($0) && !$0.hadSpeed }) {
                return "Your crab moves by changing crab.x. Move it with its speed instead: `crab.speedX = -2` in startCrab. Then `crab.speedX = -crab.speedX` can flip it."
            }
            if p.log.allSatisfy({ !moved($0) }) {
                if p.log.contains(where: { $0.turns > 2 }) { return wiggles }
                if p.builtInStart { return missing(.startCrab) }
                return stoodStill
            }
            if p.builtInUpdate { return missing(.updateCrab) }
            if p.log.contains(where: { moved($0) && $0.turns == 0 && $0.hadSpeed && $0.endSpeed == 0 }) {
                return "At a wall, a crab's speed became 0, so it stopped. `crab.speedX -= crab.speedX` makes 0. To flip it, write `crab.speedX = -crab.speedX`: the = first, then the minus sign."
            }
            if p.log.contains(where: { moved($0) && $0.turns == 0 }) {
                return "A crab got stuck at a wall. In updateCrab, flip its speed at walls: `if crab.facingWall() { crab.speedX = -crab.speedX }`. A minus sign in front flips the direction."
            }
            if p.log.contains(where: { $0.turns == 1 }) {
                return "A crab turned around once, then got stuck. `crab.speedX = -crab.speedX` flips the direction every time: the minus sign in front flips it."
            }
            if p.log.indices.contains(where: { p.log[$0].turns >= 2 && !full($0) }) {
                return "A crab shakes at a wall. Set its speed once, in startCrab. updateCrab runs 60 times a second, so a `crab.speedX = -2` there undoes the flip every frame."
            }
            return "Each crab should walk from wall to wall: `crab.speedX = -2` in startCrab, and `crab.speedX = -crab.speedX` when `crab.facingWall()` is true."
        },
    ]

    // ---------- 7. Busy Bees ----------
    static let openSky: String = {
        var rows: [String] = []
        for i in 0..<16 { rows.append(i == 8 ? ".....b....." : "...........") }
        rows.append(".P.........")
        rows.append("###########")
        return rows.joined(separator: "\n")
    }()

    struct Flight {
        /// How far it rose in the first 70 frames.
        var earlyRise = 0
        var rise = 0, drop = 0
        /// Up-to-down and down-to-up turns.
        var reversals = 0
        /// Its lowest point in each down-and-up cycle, in order.
        var lows: [Int] = []
        /// speedY kept going down, frame after frame: gravity.
        var falls = false
        var timerChanged = false
        /// The timer went back down at some point (the pattern started over).
        var timerReset = false
        /// The biggest amount the timer grew in one frame.
        var timerStep = 0
        /// The biggest value the timer had at the end of a frame.
        var maxTimer = 0
        /// Its speedY was not 0 at some point (it moved with speed, not by changing y).
        var hadSpeed = false
        /// The biggest and smallest speedY it had (the up speed and the down speed).
        var upSpeed = 0, downSpeed = 0
        var builtIn = false
    }

    static func flight(_ scripts: Scripts, frames: Int) -> Flight {
        let t = TestDrive(openSky, scripts)
        let bee = t.bees[0]
        var f = Flight()
        let startY = bee.y
        var highest = bee.y, lowest = bee.y, lastDir = 0
        var previous = bee.y, previousTimer = bee.timer, previousSpeed = bee.speedY, fallingFrames = 0
        var highestEarly = bee.y
        t.run(frames) { w in
            fallingFrames = bee.speedY < previousSpeed ? fallingFrames + 1 : 0
            if fallingFrames >= 15 { f.falls = true }
            previousSpeed = bee.speedY
            if bee.timer != 0 { f.timerChanged = true }
            if bee.timer < previousTimer { f.timerReset = true }
            f.timerStep = max(f.timerStep, bee.timer - previousTimer)
            f.maxTimer = max(f.maxTimer, bee.timer)
            if bee.speedY != 0 { f.hadSpeed = true }
            f.upSpeed = max(f.upSpeed, bee.speedY)
            f.downSpeed = min(f.downSpeed, bee.speedY)
            previousTimer = bee.timer
            let dy = bee.y - previous
            previous = bee.y
            highest = max(highest, bee.y)
            lowest = min(lowest, bee.y)
            if w.frame <= 70 { highestEarly = max(highestEarly, bee.y) }
            f.drop = max(f.drop, highest - bee.y)
            if dy != 0 {
                let dir = dy > 0 ? 1 : -1
                if lastDir != 0 && dir != lastDir {
                    f.reversals += 1
                    if dir > 0 { f.lows.append(bee.y - dy) }
                }
                lastDir = dir
            }
        }
        f.earlyRise = highestEarly - startY
        f.rise = highest - startY
        f.builtIn = t.ranBuiltIn(.updateBee)
        return f
    }

    static let beeReset = "if bee.timer == 120 { bee.timer = 0 }"

    /// Sets bee.timer to 50 and runs one frame: 51 counts once, 50 never counts, 52 counts twice,
    /// and less than 50 started over (a reset with no if, or one that comes too early).
    static func timerAfterOneFrame(_ scripts: Scripts) -> Int {
        let t = TestDrive(openSky, scripts)
        t.run(1)
        let bee = t.bees[0]
        bee.timer = 50
        t.run(1)
        return bee.timer
    }

    static let neverCounts = "The bee only goes up, because bee.timer never changes. Keep the count line `bee.timer += 1` in updateBee."
    static let countsTwice = "Your timer counts 2 every frame, so the bee turns around too soon. Is `bee.timer += 1` in updateBee twice? Keep just one."
    static let startsOverTooSoon = "The bee only goes up, because bee.timer starts over before the bee can turn around. Start over only when the timer gets to 120: `\(beeReset)`."

    static let bee: [Check] = [
        Check(title: "Bees fly up, then down") { scripts in
            let f = flight(scripts, frames: 300)
            if f.builtIn { return missing(.updateBee) }
            if f.falls { return "Your bee falls! Bees have no gravity line. Take `bee.speedY -= 1` out of updateBee." }
            if (f.rise > 0 || f.drop > 0) && !f.hadSpeed {
                return "Your bee moves by changing bee.y. Move it with its speed instead: `bee.speedY = 2`. The engine moves it by speedY every frame."
            }
            let probe = timerAfterOneFrame(scripts)
            if probe == 52 || f.timerStep >= 2 { return countsTwice }
            if f.earlyRise >= 40 && f.drop >= 40 { return nil }
            if f.rise == 0 && f.drop == 0 { return "The bee stays still. Step 1: while `bee.timer < 60`, set `bee.speedY = 2`. Otherwise set `bee.speedY = -2`." }
            if f.rise > 0 && probe == 50 { return neverCounts }
            if f.rise > 0 && (probe < 50 || (f.timerReset && f.maxTimer < 60)) { return startsOverTooSoon }
            if f.rise > 0 && f.drop == 0 { return "The bee only goes up. While `bee.timer < 60` fly up, else fly down: `else { bee.speedY = -2 }`." }
            return "The bee should go up first. While `bee.timer < 60`, set `bee.speedY = 2`. Otherwise set `bee.speedY = -2`."
        },
        Check(title: "The pattern repeats forever") { scripts in
            let f = flight(scripts, frames: 600)
            if f.builtIn { return missing(.updateBee) }
            // Each down-and-up cycle should come back to the same low point (4 points of slack, so
            // a count line moved above Step 1 still passes).
            let drift = zip(f.lows, f.lows.dropFirst()).map { abs($1 - $0) }.max() ?? 0
            if f.reversals >= 4 && drift <= 4 { return nil }
            let probe = timerAfterOneFrame(scripts)
            if probe == 52 || f.timerStep >= 2 { return countsTwice }
            if f.falls { return "Your bee falls! Bees have no gravity line. Take `bee.speedY -= 1` out of updateBee." }
            if (f.rise > 0 || f.drop > 0) && !f.hadSpeed {
                return "Your bee moves by changing bee.y. Move it with its speed instead: `bee.speedY = 2`. The engine moves it by speedY every frame."
            }
            if f.reversals >= 4 {
                if f.upSpeed != -f.downSpeed { return "Your bee drifts away a little more every time. Make the up speed and the down speed the same size: `bee.speedY = 2` and `bee.speedY = -2`." }
                return "Your bee drifts away a little more every time. Fly up while `bee.timer < 60`, and start over when it gets to 120: `\(beeReset)`. Then it flies 60 frames each way."
            }
            if f.rise == 0 && f.drop == 0 { return "The bee stays still. Step 1: while `bee.timer < 60`, set `bee.speedY = 2`. Otherwise set `bee.speedY = -2`." }
            if probe == 50 { return neverCounts }
            if probe < 50 || (f.timerReset && f.maxTimer < 60) { return startsOverTooSoon }
            if !f.timerReset { return "After 1 second the bee goes down forever, because bee.timer keeps growing. Start over: `\(beeReset)`." }
            return "Your bee stops repeating. Fly up while `bee.timer < 60`, down after that, and start over with `\(beeReset)`."
        },
    ]

    // ---------- 8. Ghost Chase ----------
    static let ghostLeft = """
    ................
    ................
    ................
    ................
    ................
    ................
    .g........P.....
    ################
    """
    static let ghostRight = """
    ................
    ................
    ................
    ................
    ................
    ................
    ....P........g..
    ################
    """
    static let ghostAbove = """
    ................
    ......g.........
    ................
    ................
    ................
    ................
    ......P.........
    ################
    """
    static let ghostBelow = """
    ................
    ......P.........
    .....###........
    ................
    ................
    ................
    ......g.........
    ################
    """

    /// 30 frames: how the ghost moved, its biggest single step (frames with an ouch don't count),
    /// whether its speed kept growing, and whether speedX / speedY were ever not 0 (it moved with
    /// speed, not by changing x or y).
    static func chase(_ map: String, _ scripts: Scripts) -> (dx: Int, dy: Int, fastest: Int, speedingUp: Bool, hadSpeedX: Bool, hadSpeedY: Bool, builtIn: Bool) {
        let t = TestDrive(map, scripts)
        let ghost = t.ghosts[0]
        let sx = ghost.x, sy = ghost.y
        var fastest = 0, early = 0
        var px = ghost.x, py = ghost.y
        var hurts = 0
        var hadSpeedX = false, hadSpeedY = false
        t.run(30) { w in
            if w.hurts == hurts { fastest = max(fastest, abs(ghost.x - px), abs(ghost.y - py)) }
            if w.frame == 5 { early = max(abs(ghost.speedX), abs(ghost.speedY)) }
            if ghost.speedX != 0 { hadSpeedX = true }
            if ghost.speedY != 0 { hadSpeedY = true }
            hurts = w.hurts
            px = ghost.x
            py = ghost.y
        }
        let late = max(abs(ghost.speedX), abs(ghost.speedY))
        return (ghost.x - sx, ghost.y - sy, fastest, early > 0 && late > early, hadSpeedX, hadSpeedY, t.ranBuiltIn(.updateGhost))
    }

    static let ghost: [Check] = [
        Check(title: "The ghost chases left and right") { scripts in
            let a = chase(ghostLeft, scripts), b = chase(ghostRight, scripts)
            let chases = a.dx > 0 && b.dx < 0
            if chases && a.hadSpeedX && b.hadSpeedX { return nil }
            if a.builtIn { return missing(.updateGhost) }
            if chases { return "Your ghost moves by changing ghost.x. Move it with its speed instead: `ghost.speedX = 1`. The engine moves it by speedX every frame." }
            let above = chase(ghostAbove, scripts), below = chase(ghostBelow, scripts)
            if above.dy == 0 && below.dy == 0 && above.dx < 0 && below.dx > 0 {
                return "Your up-and-down half sets ghost.speedX, so it undoes the left-and-right half. In the y half, set `ghost.speedY = 1` and `ghost.speedY = -1`."
            }
            return "Compare the x numbers: `if player.x > ghost.x { ghost.speedX = 1 } else { ghost.speedX = -1 }`."
        },
        Check(title: "The ghost chases up and down") { scripts in
            let a = chase(ghostAbove, scripts), b = chase(ghostBelow, scripts)
            let chases = a.dy < 0 && b.dy > 0
            if chases && a.hadSpeedY && b.hadSpeedY { return nil }
            if a.builtIn { return missing(.updateGhost) }
            if chases { return "Your ghost moves by changing ghost.y. Move it with its speed instead: `ghost.speedY = 1`. The engine moves it by speedY every frame." }
            return "Do the same with y: `if player.y > ghost.y { ghost.speedY = 1 } else { ghost.speedY = -1 }`."
        },
        Check(title: "You can outrun it") { scripts in
            let runs = [ghostLeft, ghostRight, ghostAbove, ghostBelow].map { chase($0, scripts) }
            let fastest = runs.map { $0.fastest }.max() ?? 0
            if fastest <= 3 { return nil }
            if runs.contains(where: { $0.speedingUp }) {
                return "Your ghost keeps speeding up, to \(fastest) points a frame. Set its speed with =, not +=: `ghost.speedX = 1`."
            }
            return "Your ghost moves \(fastest) points a frame, so you can't escape. Use a speed of 1, 2 or 3, like `ghost.speedX = 1`."
        },
    ]

    // ---------- 9. Stomp ----------
    static let stompDrop = """
    .......
    ...P...
    .......
    .......
    .......
    ..#c#..
    #######
    """
    static let stompWalk = """
    ............
    .P......c...
    ############
    """

    static let stomp: [Check] = [
        Check(title: "Landing on an enemy squishes it") { scripts in
            let t = TestDrive(stompDrop, scripts)
            let crab = t.crabs[0]
            var hurtTwice = false, before = 0
            t.run(90) { w in
                if w.hurts - before >= 2 { hurtTwice = true }
                before = w.hurts
            }
            if crab.removed && t.world.hurts == 0 { return nil }
            if t.ranBuiltIn(.playerTouchedEnemy) { return missing(.playerTouchedEnemy) }
            if hurtTwice { return "The old `player.hurt()` runs before your if, so you're already hurt. Delete it: the only `player.hurt()` should be inside `else { }`." }
            if crab.removed { return "You squished it, then got hurt anyway. Move `player.hurt()` inside `else { }` so it only runs when you walk into an enemy." }
            if t.world.hurts > 0 { return "Landing on the crab hurt you. Falling means player.speedY is less than 0: `if player.speedY < 0 { enemy.remove() }`." }
            return "The crab is still there. `enemy.remove()` takes it out of the game."
        },
        Check(title: "Walking into an enemy still hurts") { scripts in
            let t = TestDrive(stompWalk, scripts)
            let crab = t.crabs[0]
            t.run(90, hold: [.right])
            if t.world.hurts > 0 && !crab.removed { return nil }
            if crab.removed { return "Walking into the crab squished it. Only squish it when you're falling: `if player.speedY < 0`." }
            return "Walking into the crab didn't hurt. Add `else { player.hurt() }`."
        },
    ]
}
