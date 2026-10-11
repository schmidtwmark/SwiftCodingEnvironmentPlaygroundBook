//
//  Headless.swift  (Mac test harness only; stands in for Engine.swift, never shipped in a book)
//  GameLauncher.launch() records the page exactly like the iPad version; runHarness(), appended to
//  the end of the page's code by run-tests.sh, then does BEGIN (test drives + level), prints what the
//  student would see, lets the autopilot play, and fuzzes the level with random buttons.
//  Lines starting with "  RESULT" are read by check-results.py.
//
//  env: SEEDS, SECONDS (bot), FUZZ, FUZZFRAMES (random buttons), IDLE (seconds standing still),
//       ALLSEEDS (keep playing after a win), TRACEBOT, TRACE, BEEWINDOW=1 (Busy Bees spacing targets)
//  Sounds, bursts and shakes never play here: the harness counts them (RESULT effects=).
//

import Foundation

nonisolated(unsafe) var pendingBox: StartBox? = nil

/// The Mac side of `GameWiring.start()` (the iPad one is in Engine.swift).
enum GameLauncher {
    static func launch(_ box: StartBox) {
        pendingBox = box
        Watchdog.shared.start()
    }
}

private func env(_ name: String, _ fallback: Int) -> Int {
    Int(ProcessInfo.processInfo.environment[name] ?? "") ?? fallback
}

public func runHarness() {
    guard let box = pendingBox else { print("  GameWiring.start() was never called"); return }
    let runtime = Runtime.shared
    // BEGIN, exactly as the iPad does it (the iPad wraps each step the same way).
    runtime.begin(page: box.page, functions: box.functions, runChecks: true)
    let passed = runtime.results.filter { $0?.passed == true }.count
    print("  CHECKS \(passed)/\(runtime.results.count) passed in \(runtime.checkMilliseconds) ms")
    print("  PANEL  (what the student sees above the game)")
    for line in runtime.panelLines() { print("         | " + line) }
    let pattern = runtime.results.map { $0?.passed == true ? "✅" : "❌" }.joined()
    let hint = runtime.firstFailure?.hint.replacingOccurrences(of: "`", with: "") ?? ""
    print("  RESULT checks=\(pattern.isEmpty ? "-" : pattern)")
    // The first failing check's hint: never shown to the student, but it tells the mistakes apart.
    print("  RESULT hint=\(hint)")

    // IDLE=<seconds>: nobody touches the buttons. When does the player first get hurt?
    let idle = env("IDLE", 0)
    if idle > 0 {
        runtime.restart()
        var firstHurt = -1, gameOvers = 0, frozen = false
        for frame in 1...(idle * 60) {
            runtime.tick()
            if firstHurt < 0, (runtime.realWorld?.hurts ?? 0) > 0 { firstHurt = frame }
            if case .gameOver? = runtime.freeze { if !frozen { gameOvers += 1 }; frozen = true } else { frozen = false }
        }
        let first = firstHurt < 0 ? "never" : String(format: "%.1f s", Double(firstHurt) / 60)
        print("  IDLE   \(idle) s with no buttons: first hurt \(first), hits \(runtime.hits), game overs \(gameOvers)")
    }

    // Autopilot plays the real level.
    let seeds = env("SEEDS", 4)
    let seconds = env("SECONDS", 150)
    var outcome = "did not finish"
    var bestFrames = Int.max
    var wonSeed = -1
    var almost: Set<String> = []
    var completedSeeds = 0
    var banners: Set<String> = []
    var warnings: Set<String> = []
    var sounds = 0, bursts = 0, shakes = 0
    runtime.textLog = []
    // TRACEBOT=1: print where the bot is every second.
    let traceBot = ProcessInfo.processInfo.environment["TRACEBOT"] != nil
    let traceEvery = env("TRACEBOT", 60)
    for seed in 0..<seeds {
        runtime.restart()
        runtime.pageCompleted = false
        runtime.messageLog = []
        let bot = Autopilot(seed: UInt64(seed + 1))
        runtime.autopilot = { w in bot.next(w) }
        var frames = 0
        while frames < seconds * 60 && !runtime.pageCompleted {
            Watchdog.shared.enter()
            runtime.tick()
            Watchdog.shared.leave()
            runtime.effectQueue.removeAll(keepingCapacity: true)
            frames += 1
            if frames % 30 == 0, let warning = runtime.functionWarning { warnings.insert(warning) }
            if traceBot && frames % traceEvery == 0 {
                let near = (runtime.realWorld?.enemies ?? []).filter { !$0.removed && abs($0.x - player.x) < 150 && abs($0.y - player.y) < 150 }
                    .map { "\($0.kind.name)(\($0.x),\($0.y))" }.joined(separator: " ")
                print("    f=\(frames) player=(\(player.x),\(player.y)) speed=(\(player.speedX),\(player.speedY)) hits=\(runtime.hits) keys=\(runtime.input.now) near=\(near) texts=\(runtime.texts) msg=\(runtime.message)")
            }
        }
        runtime.autopilot = nil
        sounds += runtime.soundsPlayed
        bursts += runtime.burstsMade
        shakes += runtime.shakesMade
        runtime.effectQueue = []
        print("  SEED \(seed + 1): \(runtime.pageCompleted ? "complete" : "not complete") frames \(frames) hits \(runtime.hits)")
        if runtime.pageCompleted { completedSeeds += 1; banners.insert(runtime.message) }
        for m in runtime.messageLog where m.hasPrefix("Almost") || m.contains("first") { almost.insert(m) }
        if runtime.pageCompleted && frames < bestFrames {
            bestFrames = frames
            wonSeed = seed
            outcome = "COMPLETE"
        } else if !runtime.pageCompleted, let w = runtime.realWorld, w.flagReached, outcome != "COMPLETE" {
            outcome = "reached the 🚩 but not complete"
        }
        if runtime.pageCompleted && ProcessInfo.processInfo.environment["ALLSEEDS"] == nil { break }
    }
    if outcome == "COMPLETE" {
        print("  BOT    COMPLETE in \(String(format: "%.1f", Double(bestFrames) / 60)) s of game time (seed \(wonSeed + 1)); banner: \(runtime.message.replacingOccurrences(of: "\n", with: " / "))")
    } else {
        print("  BOT    \(outcome) after \(seeds) tries of \(seconds) s")
    }
    for m in almost.sorted() { print("  SAW    \(m)") }
    print("  RESULT bot=\(completedSeeds)/\(seeds) banner=\(banners.sorted().joined(separator: " | ").replacingOccurrences(of: "\n", with: " / "))")
    // The header's "Can't find:" line: a function from the page's starter the engine can't find.
    print("  RESULT warn=\(warnings.sorted().joined(separator: " | ").replacingOccurrences(of: "`", with: ""))")
    // What game.showText showed while the bot played (digits as #).
    print("  RESULT texts=\(runtime.textLog.sorted().joined(separator: " | "))")
    // Effects the bot's games asked for (a sound, a burst or a shake is one effect each).
    print("  RESULT effects=sounds \(sounds), bursts \(bursts), shakes \(shakes)")

    if ProcessInfo.processInfo.environment["BEEWINDOW"] != nil { beeWindow(box) }

    // Random buttons: how often does random play reach an unlocked flag?
    let runs = env("FUZZ", 0)
    if runs > 0 {
        var reached = 0, completed = 0
        let fuzzFrames = env("FUZZFRAMES", 1800)
        var rng = SeededRandom(seed: 99)
        for _ in 0..<runs {
            let result = randomRun(frames: fuzzFrames, rng: &rng, trace: ProcessInfo.processInfo.environment["TRACE"] != nil)
            if result.reached { reached += 1 }
            if result.completed { completed += 1 }
        }
        print("  FUZZ   \(runs) random runs of \(fuzzFrames / 60) s: reached an unlocked 🚩 \(reached), page complete \(completed)")
        print("  RESULT fuzz=\(reached)/\(completed)/\(runs)")
    }
}

/// One run of random buttons on the real level: did it reach an unlocked 🚩, and complete the page?
private func randomRun(frames fuzzFrames: Int, rng: inout SeededRandom, trace: Bool) -> (reached: Bool, completed: Bool) {
    let runtime = Runtime.shared
    runtime.restart()
    runtime.pageCompleted = false
    var hold = 0, left = 0
    var local = rng
    runtime.autopilot = { _ in
        if left <= 0 {
            left = Int.random(in: 4..<45, using: &local)
            hold = Int.random(in: 0..<8, using: &local)
        }
        left -= 1
        return hold
    }
    var frames = 0
    var trail: [String] = []
    while frames < fuzzFrames && !runtime.pageCompleted {
        let blink = runtime.realWorld?.blinkFrames ?? 0
        runtime.tick()
        frames += 1
        if trace && (frames % 10 == 0 || blink > 0) {
            trail.append("f\(frames) x\(player.x) y\(player.y) blink\(blink) hurts\(runtime.realWorld?.hurts ?? 0) keys\(runtime.input.now)")
        }
        if runtime.realWorld?.flagReached == true { break }
    }
    runtime.autopilot = nil
    rng = local
    let reached = runtime.realWorld?.flagReached == true
    if reached && trace { print(trail.suffix(40).joined(separator: "\n")) }
    return (reached, runtime.pageCompleted)
}

/// BEEWINDOW=1 (Busy Bees): Mark's "the bees are very difficult to get past", measured on the
/// page's real level with the page's own functions. Prints the numbers and RESULT beewindow=ok, or
/// beewindow=fail: <reasons>.
///   - every tunnel bee's shortest open window >= 75 frames and >= 4 x the 16-frame crossing;
///   - the longest closed stretch <= 45 frames;
///   - the bot finishes >= 29/30 seeds within 60 s, mean <= 15 s, <= 0.5 hits per seed;
///   - holding ▶ blindly from a random moment passes every bee unhurt >= 20% of the time;
///   - each bee's band in the first 10 s is the same as in the last 10 s of a minute;
///   - random buttons reach the 🚩 in <= 1% of 300 runs of 30 s.
private func beeWindow(_ box: StartBox) {
    let runtime = Runtime.shared
    let map = runtime.info.map
    var fails: [String] = []
    runtime.testing = true

    // 1. Open windows. A player standing on a bee's floor is hurt while |bee.y - floorY| < 48.
    let t = TestDrive(map, box.functions)
    let bees = t.bees
    var ys = Array(repeating: [Int](), count: bees.count)
    t.run(3600) { _ in for (i, b) in bees.enumerated() { ys[i].append(b.y) } }
    let crossing = 16   // 96 points of danger zone at 6 points a frame
    for (i, b) in bees.enumerated() {
        let floorY = b.startY - 8
        let col = b.startX / tileSize, row = t.world.rows - 1 - b.startY / tileSize
        let inTunnel = (0..<row).contains { t.world.tile(col: col, row: $0).isSolid }
        let tail = Array(ys[i][600..<1800])
        var runs: [(open: Bool, length: Int)] = []
        for y in tail {
            let open = abs(y - floorY) >= 48
            if let last = runs.last, last.open == open { runs[runs.count - 1].length += 1 } else { runs.append((open, 1)) }
        }
        let inner = runs.dropFirst().dropLast()
        let minOpen = inner.filter { $0.open }.map { $0.length }.min() ?? 0
        let maxClosed = inner.filter { !$0.open }.map { $0.length }.max() ?? 0
        let first = ys[i].prefix(600), last = ys[i].suffix(600)
        let sameBand = first.min() == last.min() && first.max() == last.max()
        print("  BEEWINDOW bee \(i + 1)\(inTunnel ? " (tunnel)" : " (open sky)"): y \(first.min()!)..\(first.max()!) in the first 10 s, \(last.min()!)..\(last.max()!) in the last; shortest open window \(minOpen) fr (\(String(format: "%.1f", Double(minOpen) / Double(crossing)))x the \(crossing)-frame crossing), longest closed \(maxClosed) fr")
        if !sameBand { fails.append("bee \(i + 1) drifts") }
        if inTunnel {
            if minOpen < 75 || minOpen < 4 * crossing { fails.append("bee \(i + 1) open window \(minOpen) < 75") }
            if maxClosed > 45 { fails.append("bee \(i + 1) closed \(maxClosed) > 45") }
        }
    }

    // 2. Hold ▶ blindly, starting at a random moment (0..119 frames in).
    var clean = 0
    for k in 0..<120 {
        let d = TestDrive(map, box.functions)
        d.run(k)
        let before = d.world.hurts
        d.run(60 * 14, hold: [.right])
        if d.world.hurts == before { clean += 1 }
    }
    print("  BEEWINDOW hold ▶ from a random moment: \(clean)/120 pass every bee unhurt")
    if clean * 5 < 120 { fails.append("blind hold ▶ \(clean)/120 < 20%") }
    runtime.testing = false
    runtime.drive = nil

    // 3. The bot on the real level: 30 seeds of 60 s.
    var done = 0, frames = 0, worst = 0, hits = 0
    for seed in 0..<30 {
        runtime.restart()
        runtime.pageCompleted = false
        let bot = Autopilot(seed: UInt64(seed + 1))
        runtime.autopilot = { w in bot.next(w) }
        var f = 0
        while f < 3600 && !runtime.pageCompleted { runtime.tick(); f += 1 }
        runtime.autopilot = nil
        if runtime.pageCompleted { done += 1; frames += f; worst = max(worst, f) }
        hits += runtime.hits
    }
    let mean = done > 0 ? Double(frames) / Double(done) / 60 : 0
    print(String(format: "  BEEWINDOW bot: %d/30 seeds finish within 60 s, mean %.1f s, worst %.1f s, %.2f hits per seed", done, mean, Double(worst) / 60, Double(hits) / 30))
    if done < 29 { fails.append("bot \(done)/30") }
    if mean > 15 { fails.append(String(format: "bot mean %.1f s", mean)) }
    if hits * 2 > 30 { fails.append("bot \(hits) hits in 30 seeds") }

    // 4. Random buttons: 300 runs of 30 s.
    var rng = SeededRandom(seed: 7)
    var reached = 0
    for _ in 0..<300 where randomRun(frames: 1800, rng: &rng, trace: false).reached { reached += 1 }
    print("  BEEWINDOW random buttons reach the 🚩 in \(reached)/300 runs of 30 s")
    if reached > 3 { fails.append("random play reached the 🚩 \(reached)/300") }

    print("  RESULT beewindow=" + (fails.isEmpty ? "ok" : "fail: " + fails.joined(separator: "; ")))
}

/// WIRING proof (run-tests.sh): calls each of the 21 functions the page handed to the engine once, on
/// throwaway things, and prints which of them were the engine's built-in versions. A page whose
/// functions all have the exact first lines prints none; a page whose first lines all differ (or
/// that has none) prints all 21.
public func runWiringProof() {
    guard let box = pendingBox else { print("  GameWiring.start() was never called"); return }
    let runtime = Runtime.shared
    runtime.testing = true
    let t = TestDrive("..........\n.P.c.b.g.f\n##########", box.functions)
    let s = box.functions
    let crab = t.crabs[0], bee = t.bees[0], ghost = t.ghosts[0], frog = t.frogs[0]
    let coin = Coin(), spring = Spring(), star = Star(), fireball = Fireball()
    runtime.builtInsRun = 0
    s.startPlayer(player); s.updatePlayer(player); s.startGame(game); s.updateGame(game)
    s.startCrab(crab); s.updateCrab(crab); s.startBee(bee); s.updateBee(bee)
    s.startGhost(ghost); s.updateGhost(ghost); s.startFrog(frog); s.updateFrog(frog)
    s.startFireball(fireball); s.updateFireball(fireball)
    s.playerTouchedCoin(coin); s.playerTouchedEnemy(crab); s.playerTouchedFlag()
    s.playerTouchedSpring(spring); s.playerTouchedStar(star)
    s.fireballTouchedEnemy(fireball, crab); s.playerGotHurt()
    let used = FunctionName.allCases.filter { runtime.builtInsRun & $0.bit != 0 }
    print("  RESULT builtins=\(used.count) \(used.map { $0.name }.joined(separator: ","))")
    runtime.testing = false
}
