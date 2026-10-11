//
//  Runtime.swift  (GameAPI: BEGIN, the fixed 60 Hz tick, win / lose / restart, the HUD text)
//
//  The iPad shows the goals ABOVE the game (Engine.swift, GoalHeaderView): the page title, the
//  checklist, a "can't find" line for a function the engine can't find, the goal status and the
//  inspector. The checks' hints are never shown (the Mac harness reads them to tell mistakes apart;
//  the Hints pages are the place for help). Only a function's own things (game.showText,
//  game.showMessage, "Game over") are drawn inside the game.
//
//  Platform independent. The iPad (Engine.swift) and the Mac harness (Tests/Headless.swift) both
//  call begin() once, after the page's top-level code, then tick() 60 times a second.
//

import Foundation

// MARK: - Checks and pages

struct CheckResult: Sendable {
    let title: String
    let passed: Bool
    let hint: String
}

struct Check: Sendable {
    let title: String
    /// nil = ✅, otherwise what the test saw (never shown: the Mac harness reads it).
    let run: @Sendable (Functions) -> String?
}

struct PageInfo {
    /// The page's own numbers on the inspector's second line.
    enum Inspect: Sendable {
        case score, deaths, lives, gameTimer, beeTimer, playerTimer, levelNumber
        /// How the last jump happened (Coyote Time): the engine's own measurement, since the
        /// inspector can't see the student's vars.
        case lastJump
    }

    var title: String
    var map: String
    var checks: [Check] = []
    var lock: FlagLock = .none
    /// Every function this page's starter has (the whole book so far). If the engine can't find one of
    /// them (its first line was changed, so the built-in one quietly does nothing), the header says
    /// "Can't find:" and its exact first line.
    var functions: [FunctionName] = [.startPlayer, .updatePlayer]
    var inspect: [Inspect] = []
}

/// The game numbers: the engine never changes them during play. They are remembered after the
/// page's top-level code, and game over puts them back.
struct GameNumbers: Equatable {
    var score = 0, deaths = 0, lives = 0, timer = 0
    static var current: GameNumbers {
        GameNumbers(score: game.score, deaths: game.deaths, lives: game.lives, timer: game.timer)
    }
    func apply() {
        game.score = score
        game.deaths = deaths
        game.lives = lives
        game.timer = timer
    }
}

/// The Settings the page's top-level code chose. Game over, "play again" and the checks put them
/// back, so a function that changes the sky during play can't keep it changed.
struct GameSettings {
    var skyColor = game.skyColor
    var horizon = game.horizonSetting
    var background = game.backgroundSetting
    var presetLayers = game.presetLayers
    var layers = game.layers
    var weather = game.weather
    var blockColor = game.blockColor
    var blockEmoji = game.blockEmoji
    var looks = [game.coinEmoji, game.crabEmoji, game.beeEmoji, game.ghostEmoji, game.frogEmoji,
                 game.spikeEmoji, game.flagEmoji, game.springEmoji, game.starEmoji, game.fireballEmoji]
    var showNumbers = game.showNumbers
    var soundVolume = game.soundVolumeSetting
    var maps = [game.level, game.level2, game.level3]

    func apply() {
        game.skyColor = skyColor
        game.horizonSetting = horizon
        game.backgroundSetting = background
        game.presetLayers = presetLayers
        game.layers = layers
        game.weather = weather
        game.blockColor = blockColor
        game.blockEmoji = blockEmoji
        if looks.count == 10 {
            game.coinEmoji = looks[0]; game.crabEmoji = looks[1]; game.beeEmoji = looks[2]
            game.ghostEmoji = looks[3]; game.frogEmoji = looks[4]; game.spikeEmoji = looks[5]
            game.flagEmoji = looks[6]; game.springEmoji = looks[7]; game.starEmoji = looks[8]
            game.fireballEmoji = looks[9]
        }
        game.showNumbers = showNumbers
        game.soundVolumeSetting = soundVolume
        if maps.count == 3 {
            game.level = maps[0]; game.level2 = maps[1]; game.level3 = maps[2]
        }
    }
}

// MARK: - Runtime

final class Runtime {
    nonisolated(unsafe) static let shared = Runtime()

    struct Input {
        var touch = 0, keys = 0, pad = 0, bot = 0
        var latched = 0
        var test = 0
        var now = 0
        var before = 0
        /// A press that starts and ends between two steps still counts for one step.
        mutating func pressBegan(_ key: GameKey) { latched |= key.bit }
        mutating func beginStep(testing: Bool) {
            if testing {
                now = test
            } else {
                now = touch | keys | pad | bot | latched
                latched = 0
            }
        }
        mutating func endStep() { before = now }
    }

    enum Freeze { case won, gameOver(Int) }

    static let maxTexts = 8
    static let maxTextLength = 40
    /// game.showMessage keeps at most 4 lines and 120 characters: a longer label needs a texture
    /// wider or taller than the GPU allows (8192 px in the simulator, 16384 on the iPad), and
    /// SpriteKit crashes.
    static let maxMessageLines = 4
    static let maxMessageLength = 120
    static let maxSoundsPerFrame = 16
    static let maxQueuedEffects = 400

    var input = Input()
    var page: GamePage = .design
    var info = PageInfo(title: "", map: "P")
    var functions: Functions?
    var realWorld: World?
    /// The world the functions are running in: the real one, or a check's test drive.
    var world: World?
    /// The check's test drive that is running (nil in the real game).
    var drive: TestDrive?
    var generation = 0
    var results: [CheckResult?] = []
    /// Step Through: the checks didn't run (the game itself says "Switch to Run My Code").
    var checksSkipped = false
    var checkMilliseconds = 0
    var testing = false
    var testWins = 0
    var testLoses = 0
    /// The goal status, shown ABOVE the game on the iPad: "✅ Page complete! ..." while won, or for
    /// 2 s "Almost! Fix the ❌ first." or a locked 🚩's "Collect every coin first".
    var status = ""
    var statusFrames = 0
    /// What the game view itself shows in its middle: a function's game.showMessage, "Game over",
    /// "You win! 🎉" (a page without checks), and the step-mode note.
    var gameMessage = ""
    var gameMessageFrames = 0
    /// Both as one text, the status first (the Mac harness and the test bot read it).
    var message: String {
        if status.isEmpty { return gameMessage }
        if gameMessage.isEmpty { return status }
        return status + "\n" + gameMessage
    }
    /// The last message a function showed in the step that is running. It goes under a win or
    /// "Game over" banner from the same step, whichever order the function called them in.
    var stepMessage: String? = nil
    /// Ouches in the real game since it last started over (the Mac harness reports them).
    var hits = 0
    /// This frame's game.showText lines (at most 8, each at most 40 characters). The engine
    /// clears them when a frame starts; while the game is frozen the last frame's stay.
    var texts: [String] = []
    /// The game numbers and Settings after the page's top-level code.
    var startNumbers = GameNumbers()
    var startSettings = GameSettings()
    var pendingWin = false
    var pendingLose = false
    var pendingNextLevel = false
    var freeze: Freeze? = nil
    /// A function asked about the ▼ button (isPressed(.down) or justPressed(.down)): the iPad shows it.
    var usesDown = false
    /// Sounds, bursts and shakes the real game asked for since the iPad last drained them.
    var effectQueue: [Effect] = []
    /// The sounds asked for in this frame (at most 16 count).
    var soundsThisFrame = 0
    /// Effects the real game asked for since the level was built (the Mac harness reports them).
    var soundsPlayed = 0
    var burstsMade = 0
    var shakesMade = 0
    /// A check's test drive played a sound, so the iPad starts the audio before the level shows.
    var checksPlayedSound = false
    /// Steps since the game froze (won, or game over).
    var frozenSteps = 0
    var winBanner = ""
    var stepsTaken = 0
    var pageCompleted = false
    /// Every banner and message shown (for the Mac harness).
    var messageLog: [String] = []
    /// Every distinct showText line (for the Mac harness), with its digits as #.
    var textLog: Set<String> = []
    /// Test-only: fakes button presses in the real game (Mac harness and simulator auto-driver).
    var autopilot: ((World) -> Int)? = nil
    /// One bit per FunctionName: built-in functions that ran (in the current test drive, or in the
    /// real game since the level was built).
    var builtInsRun = 0
    /// One bit per FunctionName: functions a check found missing (its result names the exact first line).
    var missingInChecks = 0
    /// game.win() and game.nextLevel() calls so far (even refused ones: a check that fails, or a
    /// frozen game). World compares it around the 🚩 event: did the event finish the level?
    var finishRequests = 0

    /// Called by every built-in function.
    func ranBuiltIn(_ function: FunctionName) { builtInsRun |= function.bit }

    // MARK: BEGIN (first main-loop turn after the page's top-level code)

    func begin(page: GamePage, functions: Functions, runChecks: Bool) {
        self.page = page
        info = page.info
        self.functions = functions
        startNumbers = GameNumbers.current
        startSettings = GameSettings()
        game.levelNumber = 1
        // A game.win(), game.lose() or game.nextLevel() in the page's top-level code ran before
        // there was a level.
        pendingWin = false
        pendingLose = false
        pendingNextLevel = false
        freeze = nil
        status = ""
        statusFrames = 0
        checksSkipped = false
        missingInChecks = 0
        if runChecks {
            self.runChecks()
        } else {
            results = info.checks.map { _ in nil }
            checksSkipped = !info.checks.isEmpty
        }
        texts = []
        buildLevel()
    }

    func runChecks() {
        guard let functions else { return }
        // Save everything a test drive can touch.
        let saved = (x: player.x, y: player.y, sx: player.speedX, sy: player.speedY, emoji: player.emoji,
                     timer: player.timer, startX: player.startX, startY: player.startY,
                     facing: player.lastFacedRight, removed: player.removed, world: player.world,
                     needsStart: player.needsStart, grounded: player.grounded)
        let savedNumbers = GameNumbers.current
        let savedSettings = GameSettings()
        let savedMessage = (status, statusFrames, gameMessage, gameMessageFrames, hits, pendingWin, pendingLose, stepMessage)
        let savedInput = input
        let savedTexts = texts
        let savedLevel = game.levelNumber
        let savedPending = pendingNextLevel
        testing = true
        // Every drive starts with a cool-down, so the student's own top-level vars (framesInAir,
        // ...) never carry a jump from one drive to the next.
        TestDrive.coolsDown = true
        let started = DispatchTime.now().uptimeNanoseconds
        results = info.checks.map { check in
            // Every check starts from the page's own numbers and Settings.
            savedNumbers.apply()
            savedSettings.apply()
            let hint = check.run(functions)
            return CheckResult(title: check.title, passed: hint == nil, hint: hint ?? "")
        }
        // ...and one more, so the real level starts settled too.
        if !info.checks.isEmpty { TestDrive.coolDown(functions) }
        TestDrive.coolsDown = false
        checkMilliseconds = Int((DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
        let failed = results.compactMap { $0 }.filter { !$0.passed }.map { $0.hint }
        missingInChecks = info.functions.filter { s in failed.contains { $0.contains(s.firstLine) } }.reduce(0) { $0 | $1.bit }
        testing = false
        drive = nil
        player.x = saved.x; player.y = saved.y; player.speedX = saved.sx; player.speedY = saved.sy
        player.emoji = saved.emoji; player.timer = saved.timer
        player.startX = saved.startX; player.startY = saved.startY
        player.lastFacedRight = saved.facing; player.removed = saved.removed; player.world = saved.world
        player.needsStart = saved.needsStart; player.grounded = saved.grounded
        builtInsRun = 0
        savedNumbers.apply()
        savedSettings.apply()
        (status, statusFrames, gameMessage, gameMessageFrames, hits, pendingWin, pendingLose, stepMessage) = savedMessage
        input = savedInput
        texts = savedTexts
        game.levelNumber = savedLevel
        pendingNextLevel = savedPending
        // Checks never play anything: the queue holds only what the real game asks for.
        effectQueue.removeAll()
        world = realWorld
    }

    /// Level 1: game.level, or the page's own map. startGame runs first.
    func buildLevel() {
        game.levelNumber = 1
        let custom = game.level.trimmingCharacters(in: .whitespacesAndNewlines)
        build(map: custom.isEmpty ? info.map : game.level, startGame: true)
        builtInsRun = 0
        soundsPlayed = 0
        burstsMade = 0
        shakesMade = 0
    }

    private func build(map: String, startGame: Bool) {
        guard let functions else { return }
        var parsed = parseMap(map)
        if parsed.rows == 0 {
            parsed = parseMap("P.......F\n#########")
            parsed.problems = ["The level map is empty, so here is a tiny one."]
        }
        let w = World(parsed, functions: functions, lock: info.lock)
        // The real game calls the game's own functions too.
        w.runsGameFunctions = true
        w.startGameDue = startGame
        realWorld = w
        world = w
        generation += 1
    }

    /// The maps after level 1 (game.level2, game.level3); "" means there isn't one.
    private var laterMaps: [String] { [game.level2, game.level3] }

    /// How many levels this game has (the panel says "level 2 of 3").
    var levelCount: Int {
        1 + laterMaps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    /// Which of those levels this is (level3 is the 2nd when level2 is empty).
    var levelOrdinal: Int {
        1 + laterMaps.prefix(max(0, game.levelNumber - 1)).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    /// game.nextLevel(), after the step: the next level that has a map, keeping the game numbers.
    /// Its start functions run (not startGame). After the last level, it's a win.
    private func goToNextLevel() {
        var n = game.levelNumber
        while n < 3 {
            n += 1
            let map = laterMaps[n - 2]
            if !map.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                game.levelNumber = n
                texts = []
                build(map: map, startGame: false)
                return
            }
        }
        requestWin()
    }

    // MARK: The fixed 60 Hz step

    func tick() {
        guard let w = realWorld else { return }
        if let f = freeze {
            // Won or game over: no steps. The last frame's texts stay on the screen.
            frozenSteps += 1
            if case .gameOver(let left) = f {
                if left <= 1 { restart() } else { freeze = .gameOver(left - 1) }
            }
            countDownMessage()
            return
        }
        world = w
        drive = nil
        stepMessage = nil
        if let autopilot { input.bot = autopilot(w) }
        input.beginStep(testing: false)
        w.step()
        input.endStep()
        stepsTaken += 1
        for text in texts { logText(text) }
        if pendingNextLevel && !pendingLose && !pendingWin {
            pendingNextLevel = false
            goToNextLevel()
        }
        pendingNextLevel = false
        if pendingLose || pendingWin { frozenSteps = 0 }
        if pendingLose {
            freeze = .gameOver(120)
            setGameMessage(banner("Game over"), frames: 120)
        } else if pendingWin {
            freeze = .won
            pageCompleted = true
            if info.checks.isEmpty {
                setGameMessage(banner(winBanner), frames: Int.max)
            } else {
                // "Page complete!" goes above the game; this step's message from a function stays in it.
                status = winBanner
                statusFrames = Int.max
                gameMessage = stepMessage ?? ""
                gameMessageFrames = Int.max
                log(banner(winBanner))
            }
        }
        pendingWin = false
        pendingLose = false
        countDownMessage()
    }

    /// A banner, with this step's message from a function under it.
    private func banner(_ text: String) -> String {
        guard let extra = stepMessage, !extra.isEmpty, extra != text else { return text }
        return text + "\n" + extra
    }

    private func countDownMessage() {
        if gameMessageFrames > 0 && gameMessageFrames != Int.max {
            gameMessageFrames -= 1
            if gameMessageFrames == 0 { gameMessage = "" }
        }
        if statusFrames > 0 && statusFrames != Int.max {
            statusFrames -= 1
            if statusFrames == 0 { status = "" }
        }
    }

    private func setGameMessage(_ text: String, frames: Int) {
        gameMessage = text
        gameMessageFrames = frames
        log(text)
    }

    private func setStatus(_ text: String, frames: Int) {
        status = text
        statusFrames = frames
        log(text)
    }

    private func log(_ text: String) {
        if messageLog.last != text { messageLog.append(text) }
        if messageLog.count > 200 { messageLog.removeFirst(100) }
    }

    private func logText(_ text: String) {
        if textLog.count >= 50 { return }
        textLog.insert(String(text.map { $0.isASCII && $0.isNumber ? "#" : $0 }))
    }

    /// Game over, or play again after a win: the game numbers and Settings go back to their start
    /// values, the game goes back to level 1 (spawned things disappear with the old level), and
    /// startGame runs first.
    func restart() {
        startNumbers.apply()
        startSettings.apply()
        hits = 0
        freeze = nil
        pendingWin = false
        pendingLose = false
        pendingNextLevel = false
        status = ""
        statusFrames = 0
        gameMessage = ""
        gameMessageFrames = 0
        stepMessage = nil
        texts = []
        buildLevel()
    }

    /// A tap on the game or a key press. After a win it starts the game again, but only after 1 s,
    /// so ▲ still being mashed at the 🚩 doesn't erase "Page complete!".
    func userPoked() {
        if case .won? = freeze, frozenSteps >= 60 { restart() }
    }

    // MARK: Called by Game and World

    /// game.showMessage: a function's message. While a check runs, the test drive records it.
    func showMessage(_ full: String) {
        var text = full.split(separator: "\n", omittingEmptySubsequences: false)
            .prefix(Runtime.maxMessageLines).joined(separator: "\n")
        if text.count > Runtime.maxMessageLength { text = String(text.prefix(Runtime.maxMessageLength)) }
        if testing {
            if let drive { drive.messages.append((drive.world.frame, text)) }
            return
        }
        stepMessage = text
        setGameMessage(text, frames: 120)
    }

    /// The engine's own goal messages ("Almost! ...", "Collect every coin first"): the status above
    /// the game.
    func engineMessage(_ text: String) {
        if testing { return }
        setStatus(text, frames: 120)
    }

    /// game.showText: one line at the top right, for this frame only.
    func showText(_ text: String) {
        if texts.count >= Runtime.maxTexts { return }
        texts.append(text.count > Runtime.maxTextLength ? String(text.prefix(Runtime.maxTextLength)) : text)
    }

    func requestWin() {
        finishRequests += 1
        if testing {
            testWins += 1
            if let drive { drive.wins += 1; drive.finishFrames.append(drive.world.frame) }
            return
        }
        if freeze != nil { return }
        if info.checks.isEmpty {
            winBanner = "You win! 🎉"
            pendingWin = true
        } else if checksSkipped {
            // Never a page complete without its checks. No status either: in Step Through the
            // functions don't run, and the game already says "Switch to Run My Code".
            return
        } else if results.contains(where: { $0?.passed == false }) {
            engineMessage("Almost! Fix the ❌ first.")
        } else {
            winBanner = "✅ Page complete! Go to the next page."
            pendingWin = true
        }
    }

    func requestLose() {
        if testing { testLoses += 1; drive?.loses += 1; return }
        if freeze != nil { return }
        pendingLose = true
    }

    /// game.nextLevel(): while a check runs, the test drive only counts it.
    func requestNextLevel() {
        finishRequests += 1
        if testing {
            if let drive { drive.nextLevels += 1; drive.finishFrames.append(drive.world.frame) }
            return
        }
        if freeze != nil { return }
        pendingNextLevel = true
    }

    /// game.playSound, thing.burst and game.shake. While a check runs, the test drive logs it;
    /// in the real game it waits in effectQueue for the iPad. At most 16 sounds a frame.
    func request(_ effect: Effect, source: Thing?) {
        if case .sound = effect {
            if soundsThisFrame >= Runtime.maxSoundsPerFrame { return }
            soundsThisFrame += 1
        }
        if testing {
            if case .sound = effect { checksPlayedSound = true }
            if let drive {
                drive.effects.append((drive.world.frame, effect, source.map { ObjectIdentifier($0) }))
            }
            return
        }
        switch effect {
        case .sound: soundsPlayed += 1
        case .burst: burstsMade += 1
        case .shake: shakesMade += 1
        }
        effectQueue.append(effect)
        if effectQueue.count > Runtime.maxQueuedEffects { effectQueue.removeFirst(effectQueue.count - Runtime.maxQueuedEffects) }
    }

    /// The effects asked for since the last call (the iPad plays and draws them).
    func takeEffects() -> [Effect] {
        if effectQueue.isEmpty { return [] }
        let taken = effectQueue
        effectQueue.removeAll(keepingCapacity: true)
        return taken
    }

    /// World.hurt() calls this. The engine shows nothing and counts nothing the student can see:
    /// playerGotHurt does that.
    func playerWasHurt() {
        if testing { return }
        hits += 1
    }

    // MARK: HUD text (the iPad draws it; the Mac harness prints it)

    var firstFailure: CheckResult? {
        for r in results { if let r, !r.passed { return r } }
        return nil
    }

    /// The checklist: the page's checks, its lock, the 🚩, and a "Can't find:" note for each function
    /// the engine can't find (at most 2). No hints. The iPad draws it above the game
    /// (GoalHeaderView); panelLines() is the same as text.
    func checklist() -> Checklist {
        var list = Checklist(title: info.title)
        var sawFailure = false
        for (i, check) in info.checks.enumerated() {
            let result = i < results.count ? results[i] : nil
            let mark = result == nil ? "⬜️" : (result!.passed ? "✅" : "❌")
            var row = ChecklistRow(mark: mark, text: check.title)
            if let result, !result.passed, !sawFailure {
                row.firstFailure = true
                sawFailure = true
            }
            list.rows.append(row)
        }
        if let w = realWorld {
            switch info.lock {
            case .coins:
                let got = w.coins.filter { $0.removed }.count
                list.rows.append(ChecklistRow(mark: got == w.coins.count ? "✅" : "⬜️", text: "Collect all \(w.coins.count) 🪙  (\(got))"))
            case .crabs:
                let crabs = w.enemies.filter { $0.kind == .crab }
                let gone = crabs.filter { $0.removed }.count
                list.rows.append(ChecklistRow(mark: gone == crabs.count ? "✅" : "⬜️", text: "Squish all \(crabs.count) 🦀  (\(gone))"))
            case .none: break
            }
            // Ticked only when the page's 🚩 event finished the level (asked for a win or the next
            // level), not on a touch: a student's playerTouchedFlag() can lock the 🚩.
            let count = levelCount
            let which = count > 1 ? "  (level \(levelOrdinal) of \(count))" : ""
            list.rows.append(ChecklistRow(mark: w.flagReached ? "✅" : "⬜️", text: "Reach the 🚩" + which))
            for missing in missingFunctions.prefix(2) {
                list.notes.append(ChecklistNote(text: Runtime.cantFind(missing), hasCode: true))
            }
        }
        return list
    }

    /// The checklist as lines of text (the Mac harness prints it).
    func panelLines(wrap: Int = 46) -> [String] {
        let list = checklist()
        var lines = [list.title]
        for row in list.rows { lines.append(row.mark + " " + row.text) }
        for note in list.notes {
            lines += note.hasCode ? wrapHint(note.text, width: wrap) : wrapText(note.text, width: wrap)
        }
        return lines
    }

    /// The functions from this page's starter that the engine can't find, so it uses the built-in
    /// ones, which do nothing: the real game ran a built-in one, or a check did (its result names
    /// the first line). It shows right away: a misspelled playerTouchedFlag would otherwise just
    /// do nothing.
    var missingFunctions: [FunctionName] {
        guard realWorld != nil else { return [] }
        let missing = builtInsRun | missingInChecks
        return info.functions.filter { missing & $0.bit != 0 }
    }

    /// "⚠️ Can't find: `func updateCrab(crab: Crab)`"
    static func cantFind(_ function: FunctionName) -> String {
        "⚠️ Can't find: `func \(function.name)(\(function.parameters))`"
    }

    /// The first function the engine can't find, as the header shows it (the Mac harness reports it).
    var functionWarning: String? {
        missingFunctions.first.map { Runtime.cantFind($0) }
    }

    /// The inspector's "last jump" words (Coyote Time).
    static func describe(_ j: World.Jump) -> String {
        if j.fromGround {
            if j.framesSinceUp > 0 { return "from the ground, without ▲!" }
            // Early jumps say how early (the Canyon: wait for the very edge).
            if j.framesToEdge == 0 { return "from the ground, at the very edge" }
            if j.framesToEdge > 0 && j.framesToEdge <= 15 {
                return "from the ground, " + String(j.framesToEdge) + (j.framesToEdge == 1 ? " frame" : " frames") + " before the edge"
            }
            return "from the ground"
        }
        if j.secondJump { return "in mid-air!" }
        return String(j.airFrames) + (j.airFrames == 1 ? " frame" : " frames") + " after the ledge 🐺 (coyote time)"
    }

    /// The inspector (gray, above the game, under the checklist): the player's numbers, then this
    /// page's own.
    /// Empty when game.showNumbers is false.
    var inspectorLines: [String] {
        guard game.showNumbers else { return [] }
        var lines = ["x \(player.x)  y \(player.y)  speedX \(player.speedX)  speedY \(player.speedY)  isOnGround \(player.isOnGround())"]
        var items: [String] = []
        for item in info.inspect {
            switch item {
            case .score: items.append("game.score \(game.score)")
            case .deaths: items.append("game.deaths \(game.deaths)")
            case .lives: items.append("game.lives \(game.lives)")
            case .gameTimer: items.append("game.timer \(game.timer)")
            case .playerTimer: items.append("player.timer \(player.timer)")
            case .levelNumber: items.append("game.levelNumber \(game.levelNumber)")
            case .lastJump:
                if let j = realWorld?.jumps.last { items.append("last jump: " + Runtime.describe(j)) }
            case .beeTimer:
                if let bee = realWorld?.enemies.first(where: { $0.kind == .bee && !$0.removed }) {
                    items.append("bee.timer \(bee.timer)")
                }
            }
        }
        if !items.isEmpty { lines.append(items.joined(separator: "  ")) }
        return lines
    }
}

// MARK: - The checklist (above the game on the iPad)

struct ChecklistRow: Equatable {
    /// ✅, ❌ or ⬜️
    var mark: String
    var text: String
    /// The first ❌ (drawn in bold).
    var firstFailure = false
}

/// A ⚠️ line under the checklist ("Can't find:"). `hasCode`: it has a `code` span (a function's first line).
struct ChecklistNote: Equatable {
    var text: String
    var hasCode = false
}

struct Checklist: Equatable {
    var title = ""
    var rows: [ChecklistRow] = []
    var notes: [ChecklistNote] = []
}

// MARK: - Watchdog (a `while` that never ends inside a function)

final class Watchdog: @unchecked Sendable {
    static let shared = Watchdog()
    static let message = "A function ran for 2 seconds without finishing. The engine already calls your update functions 60 times a second, so use if, not while."
    private let lock = NSLock()
    private var startedAt: UInt64 = 0
    private var running = false

    func enter() { lock.lock(); startedAt = DispatchTime.now().uptimeNanoseconds; lock.unlock() }
    func leave() { lock.lock(); startedAt = 0; lock.unlock() }

    func start() {
        lock.lock()
        defer { lock.unlock() }
        if running { return }
        running = true
        let thread = Thread { [self] in
            while true {
                Thread.sleep(forTimeInterval: 0.25)
                lock.lock()
                let began = startedAt
                lock.unlock()
                if began != 0 && DispatchTime.now().uptimeNanoseconds - began > 2_000_000_000 {
                    fatalError(Watchdog.message)
                }
            }
        }
        thread.name = "GameAPI function watchdog"
        thread.start()
    }
}

// MARK: - Wrapping the panel text

/// Wraps a hint for the panel and drops its backticks. A `code` span stays on one line when it
/// fits; a longer one (like a whole `func` line) breaks after its commas, then after a `{`.
func wrapHint(_ text: String, width: Int) -> [String] {
    var tokens: [String] = []
    var glue = false   // the next piece touches the previous token (no space between them)
    for (i, part) in text.split(separator: "`", omittingEmptySubsequences: false).enumerated() {
        let piece = String(part)
        if piece.isEmpty { continue }
        var words: [String]
        if i % 2 == 1 {
            words = splitCode(piece, width: width)
        } else {
            words = piece.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        }
        for (j, word) in words.enumerated() {
            if j == 0 && glue && !word.isEmpty, let last = tokens.popLast() {
                tokens.append(last + word)
            } else if !word.isEmpty {
                tokens.append(word)
            }
        }
        glue = !piece.hasSuffix(" ")
    }
    var lines: [String] = []
    var current = ""
    for token in tokens {
        if current.isEmpty {
            current = token
        } else if current.count + 1 + token.count <= width {
            current += " " + token
        } else {
            lines.append(current)
            current = token
        }
    }
    if !current.isEmpty { lines.append(current) }
    return lines
}

/// Pieces of a code span that each fit on a line, broken after ", " first, then after "{ ".
func splitCode(_ code: String, width: Int) -> [String] {
    if code.count <= width { return [code] }
    for separator in [", ", "{ "] {
        let parts = code.components(separatedBy: separator)
        if parts.count > 1 {
            let kept = separator.trimmingCharacters(in: .whitespaces)
            return parts.enumerated()
                .map { $0.offset < parts.count - 1 ? $0.element + kept : $0.element }
                .flatMap { splitCode($0, width: width) }
        }
    }
    return code.split(separator: " ").map(String.init)
}

func wrapText(_ text: String, width: Int) -> [String] {
    var lines: [String] = []
    var current = ""
    for word in text.split(separator: " ") {
        if current.isEmpty {
            current = String(word)
        } else if current.count + 1 + word.count <= width {
            current += " " + word
        } else {
            lines.append(current)
            current = String(word)
        }
    }
    if !current.isEmpty { lines.append(current) }
    return lines
}
