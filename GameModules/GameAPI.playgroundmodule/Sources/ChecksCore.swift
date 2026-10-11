//
//  ChecksCore.swift  (GameAPI: the checks of Walk, Fall, Jump, Coins, Show the Score and
//  Enemies (Crab Patrol, Busy Bees, Ghost Chase, Stomp))
//
//  A test drive builds a tiny level, fakes the buttons, runs the same World.step() as the game,
//  and measures what happened. Checks use only engine objects and literal numbers. Every page
//  carries all the code of the pages before it, so a drive only presses the buttons its check is
//  about. When a page's function has a different first line from the one the engine looks for, the
//  engine quietly uses its built-in version, which does nothing; every check notices that and names
//  the exact first line instead (the header then shows "Can't find:" and that line).
//
//  A failing check returns a hint: what the test saw. Hints are never shown (the header shows only
//  ✅ / ❌; the Hints pages are the place for help). The Mac test harness reads them to tell
//  mistakes apart (expected.tsv).
//

import Foundation

enum Checks {
    /// The hint when the engine had to use built-in functions: the page's function is missing, or its
    /// first line is not exactly the one the engine looks for (so Swift sees another function). Every
    /// built-in does nothing.
    static func missing(_ functions: FunctionName...) -> String {
        if functions.count == 1, let s = functions.first {
            return "The engine can't find your \(s.name), so it uses the built-in one, which does nothing. Its first line must be exactly `\(s.firstLine)`"
        }
        let names = functions.map { $0.name }.joined(separator: " and ")
        let lines = functions.map { "`\($0.firstLine)`" }.joined(separator: " and ")
        return "The engine can't find your \(names), so it uses the built-in ones, which do nothing. Their first lines must be exactly \(lines)"
    }

    // ---------- 1. Walk ----------
    static let flat = """
    ..............
    ......P.......
    ##############
    """

    /// Holds `keys` for 30 frames: how far the player moved, whether its speed kept growing, and
    /// whether speedX was ever not 0 (it moved with speed, not by changing x).
    static func walkTest(_ functions: Functions, hold keys: [GameKey]) -> (moved: Int, speedingUp: Bool, hadSpeed: Bool, builtIn: Bool) {
        let t = TestDrive(flat, functions)
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

    /// The hint for moving by changing x instead of speed (the same rule as Crab Patrol's).
    static let movedByX = "You moved by changing player.x. Change player.speedX instead: the engine moves you by your speed every frame."

    static let walk: [Check] = [
        Check(title: "▶ moves right") { functions in
            let right = walkTest(functions, hold: [.right])
            if right.builtIn { return missing(.updatePlayer) }
            if right.moved > 0 && !right.hadSpeed { return movedByX }
            if right.moved > 0 && right.speedingUp { return "▶ makes you go faster and faster: += adds to your speed again every frame. Set the speed with = instead." }
            if right.moved > 0 { return nil }
            if walkTest(functions, hold: []).moved != 0 { return "You move even when no button is held. Set player.speedX only inside the if / else if / else." }
            if right.moved < 0 { return "▶ moved you LEFT. Check your ifs: ▶ is `isPressed(.right)`, and going right needs a positive speedX." }
            return "Holding ▶ didn't move you. Does the ▶ part still set speedX to 6? If an if below it sets your speed back to 0, join your ifs into one chain: if, then else if, then else."
        },
        Check(title: "◀ moves left") { functions in
            let left = walkTest(functions, hold: [.left])
            if left.builtIn { return missing(.updatePlayer) }
            if left.moved < 0 && !left.hadSpeed { return movedByX }
            if left.moved < 0 && left.speedingUp { return "◀ makes you go faster and faster: -= takes away more again every frame. Set the speed with = instead." }
            if left.moved < 0 { return nil }
            if left.moved > 0 { return "◀ moved you RIGHT. Going left needs a negative speedX: a minus sign in front of the number." }
            return "Holding ◀ didn't move you. After the ▶ part, an else if can ask about ◀ (`isPressed(.left)`) and give you a speed that goes left."
        },
        Check(title: "No button, no moving") { functions in
            let idle = walkTest(functions, hold: [])
            if idle.builtIn { return missing(.updatePlayer) }
            if idle.moved != 0 { return "You moved with no button held. A last else runs when no other part is true, so it can stop you: a speedX of 0 stands still. Walking left goes in its own else if." }
            // Press a button, then let go: you should stop.
            for key in [GameKey.right, .left] {
                let t = TestDrive(flat, functions)
                t.run(10, hold: [key])
                let letGo = player.x
                t.run(30)
                if player.x != letGo {
                    return "You keep sliding after you let go, because speedX stays the same until your code changes it. With no button held, your speed should be 0: that's a last else."
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
    static func drop(_ functions: Functions, hold keys: [GameKey]) -> (dy: Int, builtIn: Bool) {
        let t = TestDrive(tall, functions)
        let start = player.y
        t.run(20, hold: keys)
        return (player.y - start, t.ranBuiltIn(.updatePlayer))
    }

    static let fall: [Check] = [
        Check(title: "You fall") { functions in
            let idle = drop(functions, hold: []), held = drop(functions, hold: [.right])
            if idle.builtIn { return missing(.updatePlayer) }
            if idle.dy < 0 && held.dy < 0 { return nil }
            if idle.dy > 0 { return "You floated UP. Gravity pulls down: speedY should get smaller every frame, not bigger." }
            if idle.dy < 0 { return "You only fall when no button is held: your gravity is inside the else. Move it below the whole if / else if / else, so it runs every frame." }
            if held.dy < 0 { return "You only fall while ▶ is held. Gravity goes at the bottom of updatePlayer, outside the ifs." }
            return "You didn't fall. Gravity changes your speed a little every frame: at the bottom of updatePlayer, outside the ifs, make player.speedY 1 smaller."
        },
        Check(title: "You fall faster and faster") { functions in
            let t = TestDrive(tall, functions)
            var ys = [player.y]
            var hadSpeed = false
            t.run(10) { _ in
                ys.append(player.y)
                if player.speedY != 0 { hadSpeed = true }
            }
            let early = ys[0] - ys[5], late = ys[5] - ys[10]
            if late > early && early >= 0 { return nil }
            if early <= 0 && late <= 0 { return "You didn't fall. Gravity changes player.speedY every frame, at the bottom of updatePlayer." }
            if !hadSpeed { return "You fall at a steady speed, because you change player.y. Change player.speedY instead: a speed that keeps changing makes you fall faster and faster." }
            return "You fall at a steady speed, because your speed is set to the same number every frame. Gravity changes it: use -= (take away), not = (set)."
        },
        Check(title: "You land and stop") { functions in
            let t = TestDrive(tall, functions)
            t.run(600)
            let landed = player.y
            var stayed = true
            t.run(30) { _ in if player.y != landed { stayed = false } }
            if player.isOnGround() && stayed { return nil }
            if player.y > 1000 { return "You went up and never came down. Gravity pulls down: speedY should get smaller every frame." }
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
        Check(title: "▲ jumps") { functions in
            // First: with no button held you stay on the ground (catches isOnGround() in place of isPressed(.up)).
            let idle = TestDrive(room, functions)
            var hopped = false
            idle.run(60) { _ in if !player.isOnGround() { hopped = true } }
            if idle.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if hopped { return "You jump even when ▲ isn't pressed. The jump has to stay inside the if that asks about ▲; ask about the ground in a second if, inside that one." }
            let t = TestDrive(room, functions)
            t.run(10)
            let ground = player.y
            var highest = ground
            t.run(3, hold: [.up]) { _ in highest = max(highest, player.y) }
            t.run(90) { _ in highest = max(highest, player.y) }
            if highest - ground >= 40 { return nil }
            if highest > ground { return "That jump is tiny. Give speedY a bigger number when you jump, like the 18 you started with." }
            return "Pressing ▲ didn't lift you. When ▲ is pressed and you stand on a block, the jump should still set speedY to 18. Is that line inside both ifs?"
        },
        Check(title: "Holding ▲ can't make you fly") { functions in
            // First: tap ▲ and let go. You have to come back down.
            let tap = TestDrive(room, functions)
            tap.run(10)
            tap.run(3, hold: [.up])
            var up = false, back = false
            tap.run(150) { _ in
                if !player.isOnGround() { up = true }
                if up && player.isOnGround() { back = true }
            }
            if tap.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            if up && !back {
                return "You jumped and never came back down. Keep the gravity line from Fall in updatePlayer."
            }
            // Then: hold ▲ the whole time.
            let t = TestDrive(room, functions)
            t.run(10)
            var leftGround = false, landed = false
            t.run(300, hold: [.up]) { _ in
                if !player.isOnGround() { leftGround = true }
                if leftGround && player.isOnGround() { landed = true }
            }
            if landed { return nil }
            if !leftGround { return "Pressing ▲ didn't lift you." }
            return "Holding ▲ lets you fly! Only jump while you stand on a block: inside the ▲ if, ask isOnGround() too, and jump only when it's true."
        },
    ]

    // ---------- 5. Coins ----------
    static let coinRow = """
    ..............
    .P...o.o.o....
    ##############
    """

    static let coins: [Check] = [
        Check(title: "A coin adds to game.score") { functions in
            let t = TestDrive(coinRow, functions)
            let start = game.score
            t.run(45, hold: [.right])
            if game.score > start { return nil }
            if t.ranBuiltIn(.playerTouchedCoin) { return missing(.playerTouchedCoin) }
            if t.ranBuiltIn(.updatePlayer) { return missing(.updatePlayer) }
            return "Touching a coin didn't change game.score. playerTouchedCoin runs when you touch one: make it add 1 to game.score."
        },
        Check(title: "Each coin counts once and disappears") { functions in
            let t = TestDrive(coinRow, functions)
            let start = game.score
            t.run(100, hold: [.right])
            t.run(30)
            let gained = game.score - start
            let left = t.world.coins.filter { !$0.removed }.count
            if t.world.hurts > 0 { return "You got hurt: the thing you removed was you! Inside playerTouchedCoin, the coin you touched is called coin." }
            if gained > 0 && left == 0 { return nil }
            if t.ranBuiltIn(.playerTouchedCoin) { return missing(.playerTouchedCoin) }
            if gained == 0 && left == 0 { return "The coins disappear, but game.score doesn't go up. Each coin should add 1 to game.score too." }
            if gained == 0 { return "Touching a coin didn't change game.score. Make playerTouchedCoin add 1 to it." }
            if left > 0 && gained == 3 { return "Each coin counted once, but it's still in the game, so the 🚩 stays locked. After you count a coin, take that coin out of the game." }
            if left > 0 { return "3 coins gave you \(gained) points: you touch a coin for many frames, and playerTouchedCoin runs on every one. After you count a coin, take that coin out of the game." }
            return "3 coins should add 3 to the score, but the score went up by \(gained). Add exactly 1 for each coin."
        },
    ]

    // ---------- 6. Show the Score ----------
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
    /// startGame), with the game's own functions on. Every frame must show the number.
    static func showsNumber(_ functions: Functions, _ a: Int, _ b: Int, function: FunctionName = .updateGame, set: (Int) -> Void) -> Shown {
        let t = TestDrive(still, functions, game: true)
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
        s.builtIn = t.ranBuiltIn(function)
        return s
    }

    /// The hints of a "your number shows on the screen" check (Show the Score, Death Counter, Lives
    /// and Game Over). `alone`: the page's other code shows no text (Show the Score), so a text that
    /// never changes must be a number the student typed. Later pages already show ⭐ and ⏱.
    static func showHint(_ s: Shown, number: String, tried: (Int, Int), alone: Bool) -> String? {
        if s.framesRight == s.frames { return nil }
        if s.builtIn { return missing(.updateGame) }
        if s.codeInQuotes { return "Your text shows the letters \"\(number)\". Inside quotes, it's just text: put \(number) outside them, turned into text with String(), and join the two with +." }
        if s.framesRight > 0 { return "Your number shows on only some frames. updateGame runs every frame: show it there, with no if around it." }
        if alone {
            if !s.anyText { return "Nothing shows up at the top right. In updateGame, show a text with game.showText, and put \(number) in it, turned into text with String()." }
            if !s.firstTexts.isEmpty && s.firstTexts == s.secondTexts { return "Your text stays the same when \(number) changes: it shows a number you typed. Turn \(number) itself into text with String()." }
            return "Your text shows a number, but not \(number). Turn \(number) into text with String(), and join it on with +."
        }
        return "None of the texts at the top right shows \(number) (the test set it to \(tried.0), then \(tried.1)). In updateGame, show it with game.showText, turned into text with String()."
    }

    static let score: [Check] = [
        Check(title: "The score shows on the screen") { functions in
            let s = showsNumber(functions, 38, 513) { game.score = $0 }
            return showHint(s, number: "game.score", tried: (38, 513), alone: true)
        },
        Check(title: "It stays on the screen") { functions in
            // Walk into a coin: the score must be on the screen every frame, before and after.
            let t = TestDrive(scoreCoin, functions, game: true)
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
                return "Your score is one frame late: it shows before the coin is counted. updateGame runs after every other function, so it sees the new score. Show it there."
            }
            let builtIn = t.ranBuiltIn(.updateGame)
            if shownFrames.isEmpty {
                if builtIn { return missing(.updateGame) }
                return "The score never shows. Show it from updateGame, which runs every frame."
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

    // ---------- 9. Crab Patrol ----------
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

    static func patrol(_ functions: Functions, frames: Int) -> (log: [Patrol], walls: [(Int, Int)], builtInStart: Bool, builtInUpdate: Bool) {
        let t = TestDrive(crabBoxes, functions)
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

    static let wiggles = "A crab wiggles in place, because it flips its speed every frame. Only flip it when it's facing a wall: ask `crab.facingWall()` first."
    static let stoodStill = "A crab stood still. The engine moves a crab by its speedX every frame, so give it a speed in startCrab: a small one, slower than you (a minus speed walks left)."

    static let crab: [Check] = [
        Check(title: "Crabs walk") { functions in
            let p = patrol(functions, frames: 60)
            if p.builtInStart && p.builtInUpdate { return missing(.startCrab, .updateCrab) }
            for l in p.log where l.maxX - l.minX < 4 {
                if l.turns > 2 { return wiggles }
                if p.builtInStart { return missing(.startCrab) }
                return stoodStill
            }
            return nil
        },
        Check(title: "Each crab turns around at walls") { functions in
            let p = patrol(functions, frames: 900)   // speed 1 needs 664 frames to touch both walls
            func full(_ i: Int) -> Bool { p.log[i].minX <= p.walls[i].0 + 4 && p.log[i].maxX >= p.walls[i].1 - 4 }
            if p.log.indices.allSatisfy({ full($0) && p.log[$0].turns >= 2 && p.log[$0].midTurns == 0 }) { return nil }
            let moved = { (l: Patrol) in l.maxX - l.minX >= 4 }
            if p.log.contains(where: { $0.midTurns > 0 }) {
                return "A crab turned around in the middle of the floor. Each crab has its own speedX: flip that crab's own speed, not a variable every crab shares."
            }
            if p.log.contains(where: { moved($0) && !$0.hadSpeed }) {
                return "Your crab moves by changing crab.x. Give it a speedX in startCrab instead: the engine moves it by its speed, and a speed is something you can flip."
            }
            if p.log.allSatisfy({ !moved($0) }) {
                if p.log.contains(where: { $0.turns > 2 }) { return wiggles }
                if p.builtInStart { return missing(.startCrab) }
                return stoodStill
            }
            if p.builtInUpdate { return missing(.updateCrab) }
            if p.log.contains(where: { moved($0) && $0.turns == 0 && $0.hadSpeed && $0.endSpeed == 0 }) {
                return "At a wall, a crab's speed became 0, so it stopped: -= takes the speed away from itself, which makes 0. To flip it, set it (=) to minus its own speed."
            }
            if p.log.contains(where: { moved($0) && $0.turns == 0 }) {
                return "A crab got stuck at a wall: the wall stops it, but its speedX stays the same. In updateCrab, when it's facing a wall, flip its speedX (a minus sign flips a number)."
            }
            if p.log.contains(where: { $0.turns == 1 }) {
                return "A crab turned around once, then got stuck: your flip sets the same speed every time. To flip whatever speed it has, use minus the crab's own speedX."
            }
            if p.log.indices.contains(where: { p.log[$0].turns >= 2 && !full($0) }) {
                return "A crab shakes at a wall. Set its starting speed once, in startCrab: updateCrab runs 60 times a second, so a speed set there undoes the flip every frame."
            }
            return "Each crab should walk from wall to wall: a speed in startCrab, and a flip in updateCrab when `crab.facingWall()` is true."
        },
    ]

    // ---------- 10. Busy Bees ----------
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

    static func flight(_ functions: Functions, frames: Int) -> Flight {
        let t = TestDrive(openSky, functions)
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

    /// Sets bee.timer to 50 and runs one frame: 51 counts once, 50 never counts, 52 counts twice,
    /// and less than 50 started over (a reset with no if, or one that comes too early).
    static func timerAfterOneFrame(_ functions: Functions) -> Int {
        let t = TestDrive(openSky, functions)
        t.run(1)
        let bee = t.bees[0]
        bee.timer = 50
        t.run(1)
        return bee.timer
    }

    static let neverCounts = "The bee only goes up, because bee.timer never changes. Keep the count line that adds 1 to bee.timer in updateBee."
    static let countsTwice = "Your timer counts 2 every frame, so the bee turns around too soon. Is the count line in updateBee twice? Keep just one."
    static let startsOverTooSoon = "The bee only goes up, because bee.timer starts over before the bee can turn around. Start the count over only when it gets to 120: put that inside an if."
    static let beeFalls = "Your bee falls! Bees have no gravity: take out the line that makes bee.speedY smaller every frame."
    static let beeMovedByY = "Your bee moves by changing bee.y. Set bee.speedY instead: the engine moves it by its speed every frame."
    static let beeStill = "The bee didn't move. It moves by its speedY, so Step 1 sets bee.speedY: up when bee.timer is under 60, down after that."

    static let bee: [Check] = [
        Check(title: "Bees fly up, then down") { functions in
            let f = flight(functions, frames: 300)
            if f.builtIn { return missing(.updateBee) }
            if f.falls { return beeFalls }
            if (f.rise > 0 || f.drop > 0) && !f.hadSpeed { return beeMovedByY }
            let probe = timerAfterOneFrame(functions)
            if probe == 52 || f.timerStep >= 2 { return countsTwice }
            if f.earlyRise >= 40 && f.drop >= 40 { return nil }
            if f.rise == 0 && f.drop == 0 { return beeStill }
            if f.rise > 0 && probe == 50 { return neverCounts }
            if f.rise > 0 && (probe < 50 || (f.timerReset && f.maxTimer < 60)) { return startsOverTooSoon }
            if f.rise > 0 && f.drop == 0 { return "The bee only goes up. After the first 60 frames of its count it should fly down: that needs an else, and down is a speedY below 0 (like falling)." }
            return "The bee should go up first: a speedY above 0 when bee.timer is under 60, and down after that."
        },
        Check(title: "The pattern repeats forever") { functions in
            let f = flight(functions, frames: 600)
            if f.builtIn { return missing(.updateBee) }
            // Each down-and-up cycle should come back to the same low point (4 points of slack, so
            // a count line moved above Step 1 still passes).
            let drift = zip(f.lows, f.lows.dropFirst()).map { abs($1 - $0) }.max() ?? 0
            if f.reversals >= 4 && drift <= 4 { return nil }
            let probe = timerAfterOneFrame(functions)
            if probe == 52 || f.timerStep >= 2 { return countsTwice }
            if f.falls { return beeFalls }
            if (f.rise > 0 || f.drop > 0) && !f.hadSpeed { return beeMovedByY }
            if f.reversals >= 4 {
                if f.upSpeed != -f.downSpeed { return "Your bee drifts away a little more every time: it flies up at speed \(f.upSpeed) but down at speed \(-f.downSpeed). Make them the same size (2 up, and 2 down), and keep gravity out of updateBee." }
                return "Your bee drifts away a little more every time. Fly up when bee.timer is under 60, and start the count over when it gets to 120: then it flies 60 frames each way."
            }
            if f.rise == 0 && f.drop == 0 { return beeStill }
            if probe == 50 { return neverCounts }
            if probe < 50 || (f.timerReset && f.maxTimer < 60) { return startsOverTooSoon }
            if !f.timerReset { return "After 1 second the bee flies down forever: bee.timer keeps growing, so it's never under 60 again. When the count gets to 120, start it over from 0." }
            return "Your bee stops repeating. Fly up when bee.timer is under 60, down after that, and start the count over at 120."
        },
    ]

    // ---------- 11. Ghost Chase ----------
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
    static func chase(_ map: String, _ functions: Functions) -> (dx: Int, dy: Int, fastest: Int, speedingUp: Bool, hadSpeedX: Bool, hadSpeedY: Bool, builtIn: Bool) {
        let t = TestDrive(map, functions)
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
        Check(title: "The ghost chases left and right") { functions in
            let a = chase(ghostLeft, functions), b = chase(ghostRight, functions)
            let chases = a.dx > 0 && b.dx < 0
            if chases && a.hadSpeedX && b.hadSpeedX { return nil }
            if a.builtIn { return missing(.updateGhost) }
            if chases { return "Your ghost moves by changing ghost.x. Set ghost.speedX instead: the engine moves it by its speed every frame." }
            let above = chase(ghostAbove, functions), below = chase(ghostBelow, functions)
            if above.dy == 0 && below.dy == 0 && above.dx < 0 && below.dx > 0 {
                return "Your up-and-down half sets ghost.speedX, so it undoes the left-and-right half. The y half sets ghost.speedY."
            }
            return "The ghost should move toward you left and right: compare player.x with ghost.x, and set ghost.speedX (that half was already on the page)."
        },
        Check(title: "The ghost chases up and down") { functions in
            let a = chase(ghostAbove, functions), b = chase(ghostBelow, functions)
            let chases = a.dy < 0 && b.dy > 0
            if chases && a.hadSpeedY && b.hadSpeedY { return nil }
            if a.builtIn { return missing(.updateGhost) }
            if chases { return "Your ghost moves by changing ghost.y. Set ghost.speedY instead: the engine moves it by its speed every frame." }
            if a.dy > 0 && b.dy < 0 { return "Your ghost runs away from you up and down. Bigger y is higher: when you're above the ghost, its speedY should be above 0, so it comes up to you." }
            return "The ghost doesn't follow you up and down. Do what the x half does, with y: compare player.y with ghost.y, and set ghost.speedY."
        },
        Check(title: "You can outrun it") { functions in
            let runs = [ghostLeft, ghostRight, ghostAbove, ghostBelow].map { chase($0, functions) }
            let fastest = runs.map { $0.fastest }.max() ?? 0
            if fastest <= 3 { return nil }
            if runs.contains(where: { $0.speedingUp }) {
                return "Your ghost keeps speeding up, to \(fastest) points a frame. Set its speed with =, not +=."
            }
            return "Your ghost moves \(fastest) points a frame, so you can't escape. Use speeds of 1, 2 or 3."
        },
    ]

    // ---------- 12. Stomp ----------
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
        Check(title: "Landing on an enemy squishes it") { functions in
            let t = TestDrive(stompDrop, functions)
            let crab = t.crabs[0]
            var hurtTwice = false, before = 0
            t.run(90) { w in
                if w.hurts - before >= 2 { hurtTwice = true }
                before = w.hurts
            }
            if crab.removed && t.world.hurts == 0 { return nil }
            if t.ranBuiltIn(.playerTouchedEnemy) { return missing(.playerTouchedEnemy) }
            if hurtTwice { return "You got hurt even though you squished it: a player.hurt() runs before your if asks anything. The only hurt belongs in the walked-into-it part." }
            if crab.removed { return "You squished it, then got hurt anyway. The hurt belongs only in the walked-into-it part: the else." }
            if t.world.hurts > 0 { return "Landing on the crab hurt you. Watch speedY in the inspector as you land on it: ask about your speed first, and squish the enemy instead of hurting yourself." }
            return "The crab is still there. Landing on it should take that enemy out of the game: inside playerTouchedEnemy it's called enemy."
        },
        Check(title: "Walking into an enemy still hurts") { functions in
            let t = TestDrive(stompWalk, functions)
            let crab = t.crabs[0]
            t.run(90, hold: [.right])
            if t.world.hurts > 0 && !crab.removed { return nil }
            if crab.removed { return "Walking into the crab squished it. Only squish it when you're falling: while you walk, player.speedY is 0, not below 0." }
            return "Walking into the crab didn't hurt. When you're not falling onto it, it should still hurt you, like before."
        },
    ]
}
