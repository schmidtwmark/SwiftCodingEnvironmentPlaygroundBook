// Engine rule tests: the movement rule, facing, start/update order, whole-number timers, touch
// events, playerGotHurt, startGame/updateGame, showText, the game numbers, banners, built-ins (all
// 21 do nothing), effects (sounds, bursts, shakes, the synth and mixer, particles, weather),
// backgrounds and layers, game.spawn and fireballs, the ▼ button, game.nextLevel(), game.soundVolume,
// and the game-feel support: the jump log, the cool-down between check drives, the 🚩 tick only on
// a real finish, the header's short status and its "Can't find:" line (and no hints).
// run-tests.sh builds this into one executable with the engine's platform-independent files and
// Headless (so it can see internals) and runs it before the page versions:
//   swiftc -swift-version 5 -parse-as-library -module-name GameAPI <Sources except Engine.swift> Headless.swift Autopilot.swift EngineRules.swift
import Foundation

nonisolated(unsafe) var failures = 0
func expect(_ ok: Bool, _ what: String) {
    print((ok ? "ok   " : "FAIL ") + what)
    if !ok { failures += 1 }
}

func drive(_ map: String, _ s: Functions, frames: Int, hold: [GameKey] = [], game gameFunctions: Bool = false, each: (World) -> Void = { _ in }) -> TestDrive {
    let t = TestDrive(map, s, game: gameFunctions)
    t.run(frames, hold: hold, each: each)
    return t
}

func resetNumbers() {
    game.score = 0; game.deaths = 0; game.lives = 0; game.timer = 0
}

@main
struct Semantics {
    static func main() {
        let runtime = Runtime.shared
        runtime.testing = true   // like the page checks: win/lose only count
        resetNumbers()

        // 1. Start functions run once, before the first update; the parameter is the global player.
        var s = Functions.none
        var log: [String] = []
        s.startPlayer = { p in log.append("startPlayer \(p === player)") }
        s.updatePlayer = { _ in if log.count < 3 { log.append("updatePlayer") } }
        s.startCrab = { c in log.append("startCrab x=\(c.x)") }
        _ = drive(".....\n.P.c.\n#####", s, frames: 120)
        expect(log.prefix(3) == ["startPlayer true", "startCrab x=224", "updatePlayer"], "start functions: player, then each enemy, once, before the first update; the parameter is the global player (\(log.prefix(3)))")
        expect(log.filter { $0.hasPrefix("start") }.count == 2, "start functions ran exactly once in 120 frames")

        // 2. Timers are whole numbers and never count by themselves.
        s = Functions.none
        var t = drive("...\n.b.\n.P.\n###", s, frames: 300, game: true)
        expect(t.bees[0].timer == 0 && player.timer == 0 && game.timer == 0, "timers stay 0 unless a function counts (bee \(t.bees[0].timer), player \(player.timer), game \(game.timer))")
        s.updateBee = { b in b.timer += 1 }
        s.updateGame = { g in g.timer += 1 }
        t = drive("...\n.b.\n.P.\n###", s, frames: 600, game: true)
        expect(t.bees[0].timer == 600 && game.timer == 600, "timer += 1 counts frames exactly: 600 frames is 600 (bee \(t.bees[0].timer), game \(game.timer)); 60 frames is 1 second")
        var hitExactly = false
        s.updateBee = { b in b.timer += 1; if b.timer == 120 { hitExactly = true; b.timer = 0 } }
        t = drive("...\n.b.\n...\n###", s, frames: 240)
        expect(hitExactly && t.bees[0].timer == 0, "whole numbers count exactly, so bee.timer == 120 is true")
        resetNumbers()

        // 3. One movement rule: the engine moves things by speedX/speedY; a side bump keeps speedX;
        //    landing sets speedY to 0; nothing falls without gravity.
        s = Functions.none
        s.startCrab = { c in c.speedX = -2 }
        var speeds: [Int] = []
        t = drive("......\n#.c..#\n######", s, frames: 60) { w in speeds.append(w.enemies[0].speedX) }
        let crab = t.crabs[0]
        expect(crab.x == 64 + 24, "a crab with speedX -2 walks left until the wall stops it (x=\(crab.x))")
        expect(speeds.allSatisfy { $0 == -2 }, "bumping the wall keeps speedX at -2")
        expect(crab.facingWall() && !crab.facesRight, "facingWall() is true at the wall, facing left (the sign of speedX)")
        s.updateCrab = { c in if c.facingWall() { c.speedX = -c.speedX } }
        t = drive("......\n#.c..#\n######", s, frames: 200)
        let crab2 = t.crabs[0]
        expect(crab2.speedX == 2 || crab2.speedX == -2, "flipping keeps the size of the speed")
        var minX = Int.max, maxX = Int.min
        t.run(400) { w in minX = min(minX, w.enemies[0].x); maxX = max(maxX, w.enemies[0].x) }
        expect(minX == 88 && maxX == 5 * 64 - 24, "crab patrols wall to wall (\(minX)...\(maxX))")
        // Facing remembers the last non-zero direction.
        s = Functions.none
        s.startCrab = { c in c.speedX = 3 }
        s.updateCrab = { c in if c.timer > 12 { c.speedX = 0 }; c.timer += 1 }
        t = drive("........\n..c.....\n########", s, frames: 60)
        expect(t.crabs[0].speedX == 0 && t.crabs[0].facesRight && t.crabs[0].lastFacedRight, "speedX 0 keeps facing the last way it moved (right)")
        let fresh = TestDrive("........\n..c.P...\n########", Functions.none)
        expect(!fresh.crabs[0].facesRight && player.facesRight, "enemies start facing left, the player right")
        // Gravity only if a function adds it.
        s = Functions.none
        t = drive("....\n.b..\n....\n.c..\n....\n####", s, frames: 60)
        expect(t.world.enemies.allSatisfy { $0.y == $0.startY }, "nothing falls without its own gravity line")
        s.updateCrab = { c in c.speedY -= 1 }
        var landedSpeed = 99
        t = drive("....\n.c..\n....\n....\n####", s, frames: 90) { w in landedSpeed = w.enemies[0].speedY }
        expect(t.crabs[0].isOnGround() && landedSpeed == 0, "landing sets speedY to 0 (speedY \(landedSpeed))")
        // Head bump.
        s = Functions.none
        s.startPlayer = { p in p.speedY = 20 }
        var bumped = 99
        t = drive("####\n....\n.P..\n####", s, frames: 8) { _ in bumped = player.speedY }
        expect(bumped == 0, "bumping your head sets speedY to 0")
        // Ghosts float through blocks; coins move by speed too, and blocks stop them.
        s = Functions.none
        s.startGhost = { g in g.speedX = 4 }
        t = drive("........\ng..#....\n########", s, frames: 60)
        expect(t.ghosts[0].x == 32 + 60 * 4, "ghosts float through blocks: 60 frames at speed 4 from x=32, a block in the way (x=\(t.ghosts[0].x))")
        s = Functions.none
        t = TestDrive("......\n.o..#.\n######", s)
        let coin = t.world.coins[0]
        coin.speedX = 5
        t.run(60)
        expect(coin.x == 4 * 64 - 24 && coin.speedX == 5, "a coin with speedX moves, and a block stops it (x=\(coin.x))")
        // Setting x far away puts the thing there (teleport); a small change is swept like speed.
        s = Functions.none
        var once = true
        s.updatePlayer = { p in if once { p.x = 7 * 64 + 32; once = false } }
        _ = drive("..........\n.P...#....\n##########", s, frames: 2)
        expect(player.x == 7 * 64 + 32, "setting player.x far away teleports, even past a wall (x=\(player.x))")
        s.updatePlayer = { p in p.x += 6 }
        _ = drive("..........\n.P..#.....\n##########", s, frames: 60)
        expect(player.x == 4 * 64 - 24, "a small x change each frame is swept, so the wall still stops it (x=\(player.x))")

        // 4. player.hurt(): everything back to the start, and the start functions run again.
        s = Functions.none
        var starts = 0, crabStarts = 0
        s.startPlayer = { p in starts += 1; p.speedX = 2 }
        s.startCrab = { c in crabStarts += 1; c.speedX = -1 }
        s.updatePlayer = { p in p.timer += 1; if p.timer == 30 { p.hurt() } }
        t = drive("..........\n.P....c...\n##########", s, frames: 40)
        expect(starts == 2 && crabStarts == 2, "after player.hurt() the start functions run again (player \(starts), crab \(crabStarts))")
        expect(t.world.hurts == 1 && player.timer < 12, "an ouch resets the player's timer to 0 (timer \(player.timer))")

        // 4b. A hurt in the middle of the update functions: things that were put back wait for their
        //     start function (next frame) before they update again (Start always before Update).
        s = Functions.none
        var order: [String] = []
        var frameNo = 0
        s.updatePlayer = { p in frameNo += 1; if frameNo == 20 { order.append("hurt"); p.hurt() } }
        s.startCrab = { c in if frameNo >= 19 { order.append("start\(c.x)") } }
        s.updateCrab = { c in if frameNo >= 19 && frameNo <= 21 { order.append("update\(c.x)") } }
        _ = drive("..........\n.P..c..c..\n##########", s, frames: 22)
        expect(order == ["update288", "update480", "hurt", "start288", "start480", "update288", "update480"],
               "after a hurt inside updatePlayer, each crab's start function runs before its next update (\(order))")

        // 5. Touch events get the thing. The built-in enemy and flag events do nothing: an enemy hurts
        //    and the 🚩 wins only because the page's own code says so.
        s = Functions.none
        var touched: [String] = []
        s.playerTouchedCoin = { c in touched.append("coin \(c.kind.name)"); c.remove() }
        s.playerTouchedEnemy = { e in touched.append("enemy \(e.kind.name)"); e.remove() }
        s.updatePlayer = { p in p.speedX = 6 }
        _ = drive("..........\n.P.o.c....\n##########", s, frames: 60)
        expect(touched == ["coin coin", "enemy crab"], "touch events get the coin and the enemy (\(touched))")
        s.playerTouchedEnemy = { e in playerTouchedEnemy(enemy: e) }   // the module's built-in
        t = drive("..........\n.P...c....\n##########", s, frames: 60)
        expect(t.world.hurts == 0 && t.ranBuiltIn(.playerTouchedEnemy) && player.x > 5 * 64, "the built-in playerTouchedEnemy does nothing: walking into a crab doesn't hurt")
        s.playerTouchedFlag = { playerTouchedFlag() }
        t = drive("......\n.P..F.\n######", s, frames: 60)
        expect(t.wins == 0 && t.ranBuiltIn(.playerTouchedFlag) && t.world.flagTouched && !t.world.flagReached, "the built-in playerTouchedFlag does nothing: no win, and the 🚩 is touched but not reached")
        s.playerTouchedFlag = { game.showMessage("🪙 2 coins left!") }
        t = drive("......\n.P..F.\n######", s, frames: 60)
        expect(!t.world.flagReached && t.world.flagTouched && !t.messages.isEmpty, "a 🚩 event that only shows a message doesn't count as reaching the 🚩")
        s.playerTouchedFlag = { game.nextLevel() }
        t = drive("......\n.P..F.\n######", s, frames: 60)
        expect(t.world.flagReached && t.nextLevels > 0 && !t.finishFrames.isEmpty, "a 🚩 event that asks for the next level reaches the 🚩, and the drive logs the frame")

        // 6. Springs (s) and stars (*): pickups with their own touch events. `*` is not a flag.
        s = Functions.none
        var springTouches = 0, starTouches = 0
        s.updatePlayer = { p in p.speedX = 6 }
        s.playerTouchedSpring = { sp in springTouches += 1; if springTouches == 1 { expect(sp.kind == .spring && sp.emoji == "🍄", "playerTouchedSpring gets the 🍄") } }
        s.playerTouchedStar = { st in starTouches += 1; st.remove() }
        t = drive("..........\n..........\n.P..s..*..\n##########", s, frames: 60)
        expect(springTouches > 1 && starTouches == 1, "a spring touches every frame you overlap it (\(springTouches)); a removed star touches once (\(starTouches))")
        let springStart = t.world.springs[0]
        expect(springStart.startY == 64 + 24 && t.world.stars[0].startY == 64 + 32, "a 🍄 stands on its floor; a ⭐ floats in the middle of its square")
        let starMap = parseMap("..*..\n.P...\n#####")
        expect(!starMap.placements.contains { $0.kind == .flag } && starMap.problems.contains { $0.contains("F") }, "`*` is a star, not a flag: a map with only `*` asks for an F")
        expect(parseMap("Ps*F\n####").problems.isEmpty, "s and * are in the legend")

        // 7. playerGotHurt runs ONCE per ouch, for an enemy, spikes, a fall and player.hurt(), at the
        //    end of that frame; a player.hurt() inside it does nothing.
        func gotHurtCount(_ map: String, hold: [GameKey], frames: Int, _ extra: (inout Functions) -> Void = { _ in }) -> (runs: Int, hurts: Int, frame: [Int]) {
            var sc = Functions.none
            var runs = 0
            var when: [Int] = []
            sc.updatePlayer = { p in
                if isPressed(.right) { p.speedX = 6 } else { p.speedX = 0 }
                p.speedY -= 1
            }
            sc.playerTouchedEnemy = { _ in player.hurt() }
            extra(&sc)
            let inner = sc.playerGotHurt
            var world: World?
            sc.playerGotHurt = { runs += 1; when.append(world?.frame ?? -1); inner() }
            let d = TestDrive(map, sc)
            world = d.world
            d.run(frames, hold: hold)
            return (runs, d.world.hurts, when)
        }
        let byEnemy = gotHurtCount("..........\n.P...c....\n##########", hold: [.right], frames: 40)
        let bySpikes = gotHurtCount("..........\n.P...^....\n##########", hold: [.right], frames: 40)
        let byFall = gotHurtCount("..........\n.P........\n####..####", hold: [.right], frames: 90)
        expect(byEnemy.runs == 1 && byEnemy.hurts == 1, "an enemy ouch runs playerGotHurt once (\(byEnemy.runs) for \(byEnemy.hurts) ouches)")
        expect(bySpikes.runs == 1 && bySpikes.hurts == 1, "a spike ouch runs playerGotHurt once (\(bySpikes.runs))")
        expect(byFall.runs == 1 && byFall.hurts == 1, "falling out of the level runs playerGotHurt once (\(byFall.runs))")
        var functionFrames = 0
        let byFunction = gotHurtCount("..........\n.P........\n##########", hold: [], frames: 30) { sc in sc.updatePlayer = { p in functionFrames += 1; if functionFrames == 5 { p.hurt() } } }
        expect(byFunction.runs == 1 && byFunction.hurts == 1 && byFunction.frame == [5], "a player.hurt() in a function runs playerGotHurt once, at the end of that frame (\(byFunction.frame))")
        let inside = gotHurtCount("..........\n.P...c....\n##########", hold: [.right], frames: 40) { sc in sc.playerGotHurt = { player.hurt() } }
        expect(inside.runs == 1 && inside.hurts == 1, "a player.hurt() inside playerGotHurt does nothing (ouches \(inside.hurts))")
        var hurtFrame = 0
        var gotHurtFrame = 0
        s = Functions.none
        s.updatePlayer = { p in if p.timer == 0 { p.timer = 1 } }
        s.playerGotHurt = { gotHurtFrame = runtime.world?.frame ?? -1 }
        t = TestDrive(".....\n.P...\n#####", s)
        t.run(3)
        t.world.hurt()
        hurtFrame = t.world.frame
        t.run(3)
        expect(gotHurtFrame == hurtFrame + 1, "a hurt between frames (a check's world.hurt()) runs playerGotHurt at the end of the next frame (\(gotHurtFrame) after \(hurtFrame))")
        s = Functions.none
        var builtInMessages: [String] = []
        s.playerGotHurt = { playerGotHurt() }
        t = TestDrive(".....\n.P...\n#####", s)
        t.run(1); t.world.hurt(); t.run(1)
        builtInMessages = t.messages.map { $0.text }
        expect(builtInMessages.isEmpty && t.ranBuiltIn(.playerGotHurt), "the built-in playerGotHurt does nothing: no \"Ouch!\" unless the page says so (\(builtInMessages))")

        // 8. startGame runs first on frame 1 (before startPlayer), and after restart; never after an
        //    ouch. updateGame runs last, and only in the real game or a drive made with game: true.
        s = Functions.none
        var calls: [String] = []
        s.startGame = { _ in calls.append("startGame") }
        s.startPlayer = { _ in calls.append("startPlayer") }
        s.updatePlayer = { _ in calls.append("updatePlayer") }
        s.playerGotHurt = { calls.append("gotHurt") }
        s.updateGame = { _ in calls.append("updateGame") }
        t = drive(".....\n.P...\n#####", s, frames: 2, game: true)
        expect(calls == ["startGame", "startPlayer", "updatePlayer", "updateGame", "updatePlayer", "updateGame"], "frame order: startGame, start functions, updates, updateGame last (\(calls))")
        calls = []
        t.world.hurt()
        t.run(2)
        expect(!calls.contains("startGame") && calls.prefix(4) == ["startPlayer", "updatePlayer", "gotHurt", "updateGame"], "an ouch runs startPlayer and playerGotHurt, never startGame (\(calls))")
        calls = []
        _ = drive(".....\n.P...\n#####", s, frames: 3)
        expect(!calls.contains("startGame") && !calls.contains("updateGame"), "a drive without game: true never runs startGame or updateGame")
        // updateGame sees the frame's final numbers: the coin touched this frame is already counted.
        s = Functions.none
        var seen: [Int] = []
        s.updatePlayer = { p in p.speedX = 6 }
        s.playerTouchedCoin = { c in game.score += 1; c.remove() }
        s.updateGame = { g in seen.append(g.score) }
        var scoreAtEnd: [Int] = []
        t = drive("......\n.P.o..\n######", s, frames: 30, game: true) { _ in scoreAtEnd.append(game.score) }
        expect(seen == scoreAtEnd, "updateGame sees every frame's final numbers (score \(seen.last ?? -1))")
        resetNumbers()

        // 9. showText: this frame only, at most 8 lines of at most 40 characters.
        s = Functions.none
        s.updateGame = { g in
            if g.timer < 2 { for i in 1...10 { g.showText("line " + String(i)) } }
            g.showText(String(repeating: "x", count: 50))
            g.timer += 1
        }
        t = drive(".....\n.P...\n#####", s, frames: 3, game: true)
        expect(t.shown(inFrame: 1).count == 8 && t.shown(inFrame: 1).first == "line 1", "at most 8 lines a frame; the 9th and later are dropped (\(t.shown(inFrame: 1).count))")
        expect(t.shown(inFrame: 3) == [String(repeating: "x", count: 40)], "texts clear every frame, and each is cut to 40 characters (\(t.shown(inFrame: 3).map { $0.count }))")
        expect(t.shows(1, inFrame: 1) && !t.shows(0, inFrame: 1) && wholeNumbers(in: "⭐ 138 / -5") == [138, -5] && !wholeNumbers(in: "138").contains(38), "shows(n) matches whole numbers only: 38 is not in 138")
        resetNumbers()

        // 10. The engine never changes the game numbers during play, not even after ouches.
        game.score = 5; game.deaths = 2; game.lives = 3; game.timer = 7
        s = Functions.none
        s.updatePlayer = { p in if isPressed(.right) { p.speedX = 6 } else { p.speedX = 0 }; p.speedY -= 1 }
        s.playerTouchedEnemy = { _ in player.hurt() }
        t = drive("..........\n.P...c.^..\n##########", s, frames: 600, hold: [.right], game: true)
        expect(t.world.hurts >= 3 && GameNumbers.current == GameNumbers(score: 5, deaths: 2, lives: 3, timer: 7),
               "\(t.world.hurts) ouches and 600 frames leave score, deaths, lives and timer alone (\(GameNumbers.current))")
        resetNumbers()

        // 11. coinsLeft and enemiesLeft follow the world the functions run in (a check's drive too).
        s = Functions.none
        var counts: [Int] = []
        s.updatePlayer = { p in p.speedX = 6 }
        s.playerTouchedCoin = { c in c.remove() }
        s.updateGame = { g in counts.append(g.coinsLeft * 10 + g.enemiesLeft) }
        _ = drive("..........\n.P.o.o...g\n##########", s, frames: 40, game: true)
        expect(counts.first == 21 && counts.last == 1, "game.coinsLeft and game.enemiesLeft count the drive's own level (\(counts.first ?? -1) -> \(counts.last ?? -1))")

        // 12. Built-ins: all 21 do nothing, on every page. Nothing moves, wins, hurts, counts or shows.
        var builtInsDoNothing = true
        for page in GamePage.allCases {
            runtime.info = page.info
            game.score = 0
            t = drive("..........\n.P.o.c.^.F\n##########", builtInFunctions(), frames: 120, hold: [.right, .up], game: true)
            if player.x != 96 || player.y != 88 || t.crabs[0].x != 352 || t.world.hurts != 0 || game.score != 0 || t.wins + t.loses + t.nextLevels != 0
                || !t.messages.isEmpty || !t.shown(inFrame: 120).isEmpty || !t.effects.isEmpty || !t.world.jumps.isEmpty { builtInsDoNothing = false }
        }
        expect(builtInsDoNothing, "on every page all 21 built-ins do nothing: nobody moves, wins, gets hurt, scores or shows anything")
        // The bee the pages teach bobs 120 points, 60 frames each way, with no drift.
        s = Functions.none
        s.updateBee = { bee in
            if bee.timer < 60 { bee.speedY = 2 } else { bee.speedY = -2 }
            bee.timer += 1
            if bee.timer == 120 { bee.timer = 0 }
        }
        var beeYs: [Int] = []
        t = drive("....\n....\n....\n....\n.b..\n....\n####", s, frames: 600) { w in beeYs.append(w.enemies[0].y) }
        expect(beeYs.prefix(120).min() == beeYs.suffix(120).min() && (beeYs.max() ?? 0) - (beeYs.min() ?? 0) == 120, "Busy Bees' bee bobs 120 points, 60 frames each way, with no drift")
        runtime.info = PageInfo(title: "", map: "P")
        resetNumbers()

        // 13. The real game: startGame, restart, banners (a same-step message goes under them),
        //     game numbers and Settings put back by game over.
        runtime.testing = false
        game.level = ".........\n.P.....F.\n#########"
        game.score = 4; game.lives = 2
        game.skyColor = .hex("123456")
        var startGames = 0
        s = Functions.none
        s.startGame = { g in startGames += 1; g.lives = 3 }
        var skyChanged = false
        s.updatePlayer = { p in p.speedX = 6; if p.timer == 5 && !skyChanged { skyChanged = true; game.skyColor = .white }; p.timer += 1 }
        s.playerTouchedFlag = { game.showMessage("🏁 fast!"); game.lose() }
        runtime.begin(page: .design, functions: s, runChecks: false)
        for _ in 0..<60 { runtime.tick() }
        expect(startGames == 1 && game.lives == 3 && skyChanged && game.skyColor == .white, "the real game runs startGame once when it starts (lives \(game.lives))")
        expect(runtime.message == "Game over\n🏁 fast!", "game.lose() shows \"Game over\" with the same frame's message under it (\(runtime.message.debugDescription))")
        for _ in 0..<121 { runtime.tick() }
        expect(startGames == 2 && game.score == 4 && game.skyColor == .hex("123456"), "game over puts the game numbers and Settings back and runs startGame again (startGame \(startGames), score \(game.score))")
        s.playerTouchedFlag = { game.win(); game.showMessage("⭐ " + String(game.score)) }
        runtime.begin(page: .design, functions: s, runChecks: false)
        for _ in 0..<60 { runtime.tick() }
        expect(runtime.message == "You win! 🎉\n⭐ 4" && runtime.pageCompleted, "game.win() keeps a message from the same frame under the banner, whichever comes first (\(runtime.message.debugDescription))")
        runtime.pageCompleted = false
        // Pages with checks: the 🚩 is gated by the checklist, with no banner.
        s.playerTouchedFlag = { game.win() }
        runtime.begin(page: .walk, functions: s, runChecks: true)
        for _ in 0..<60 { runtime.tick() }
        expect(!runtime.pageCompleted && runtime.status == "Almost! Fix the ❌ first.", "a lesson page's 🚩 says only \"Almost! Fix the ❌ first.\" until every check is ✅ (\(runtime.status))")
        // Checks put the game numbers and Settings back.
        game.level = ""
        game.score = 9; game.deaths = 1
        game.skyColor = .hex("abcdef")
        runtime.begin(page: .deathCounter, functions: builtInFunctions(), runChecks: true)
        expect(game.score == 9 && game.deaths == 1 && game.skyColor == .hex("abcdef") && runtime.drive == nil && runtime.world === runtime.realWorld,
               "after the checks, the game numbers, Settings and world are the page's own again (score \(game.score))")
        // The inspector.
        runtime.begin(page: .bee, functions: Functions.none, runChecks: false)
        runtime.tick()
        let inspector = runtime.inspectorLines
        expect(inspector.count == 2 && inspector[0].hasPrefix("x ") && inspector[1].contains("game.score 9") && inspector[1].contains("bee.timer 0"), "the inspector shows x, y, speeds, isOnGround, then the page's numbers (\(inspector))")
        game.showNumbers = false
        expect(runtime.inspectorLines.isEmpty, "game.showNumbers = false hides the inspector")
        game.showNumbers = true
        runtime.testing = true
        resetNumbers()

        // 14. Level rule: a bee's whole 120-point bob fits, so every bee has at least 2 empty squares
        //     above its own (a 3-tall tunnel, like Busy Bees'), and the Death Counter, Lives and Design
        //     Your Own Game maps give it 3 (the sandbox's tip). Star Power's bee tunnel is the one exception.
        for page in GamePage.allCases where page != .starPower {
            let map = parseMap(page.info.map)
            let need = [.deathCounter, .lives, .design].contains(page) ? 3 : 2
            for p in map.placements where p.kind == .bee {
                let blockedAbove = (max(0, p.row - need)..<p.row).contains { map.tiles[$0][p.col].isSolid }
                expect(!blockedAbove, "\(page.info.title): the bee in column \(p.col) has \(need) empty squares above it")
            }
        }

        // 15. The functions table: 21 functions with their exact first lines.
        expect(FunctionName.allCases.count == 21, "21 functions")
        expect(FunctionName.updatePlayer.firstLine == "func updatePlayer(player: Player) {"
               && FunctionName.fireballTouchedEnemy.firstLine == "func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) {"
               && FunctionName.playerGotHurt.firstLine == "func playerGotHurt() {"
               && FunctionName.updateGame.firstLine == "func updateGame(game: Game) {", "first lines have no deltaTime")
        expect(GamePage.allCases.count == 23, "23 pages with code (the 24th, README, has none)")
        expect(GamePage.allCases.map { $0.info.title } == ["1. Walk", "2. Fall", "3. Jump", "4. Coyote Time",
            "5. Coins", "6. Show the Score", "7. Sounds", "8. Sparkles", "9. Crab Patrol", "10. Busy Bees", "11. Ghost Chase", "12. Stomp",
            "13. Hero Moves", "14. Backgrounds", "15. Boing!", "16. Star Power", "17. Fireballs", "18. Stopwatch", "19. Death Counter",
            "20. Lives and Game Over", "21. Locked Flag", "22. Level 2", "23. Design Your Own Game"], "the pages are one chain, titled 1 to 23 in order")
        // Every page's functions list keeps all the earlier pages' functions (the chain never drops one).
        var chainGrows = true
        for (a, b) in zip(GamePage.allCases, GamePage.allCases.dropFirst()) where !Set(a.info.functions).isSubset(of: Set(b.info.functions)) { chainGrows = false }
        expect(chainGrows && GamePage.design.info.functions.count == 16, "each page's functions include every earlier page's (\(GamePage.design.info.functions.count) by the last page)")

        effectsAndFeatures()
        gameFeel()
        print(failures == 0 ? "ALL ENGINE RULES OK" : "\(failures) FAILED")
        exit(failures == 0 ? 0 : 1)
    }
}

// MARK: - Effects, backgrounds, spawn, levels (v3 part 2)

func effectsAndFeatures() {
    let runtime = Runtime.shared
    runtime.testing = true
    resetNumbers()

    // 16. Effects go to the test drive's log (with the frame and the thing that made a burst), never
    //     to the real game's queue. Bursts remember where the thing was, even after remove().
    var s = Functions.none
    s.updatePlayer = { p in p.speedX = 6 }
    s.playerTouchedCoin = { c in c.remove(); c.burst("✨"); game.playSound(.coin) }
    runtime.effectQueue = []
    var t = drive("..........\n.P.o......\n##########", s, frames: 40)
    let coin = t.world.coins[0]
    let bursts = t.bursts(by: coin)
    var burstAt = (x: 0, y: 0)
    for e in t.effects { if case .burst(_, _, _, let x, let y) = e.effect { burstAt = (x, y) } }
    expect(bursts.count == 1 && t.sounds.count == 1 && t.sounds[0].frame == bursts[0] && t.world.coinTouchFrames == bursts,
           "a coin's burst and sound are logged once, in the frame it was touched (bursts \(bursts), sounds \(t.sounds.map { $0.frame }))")
    expect(burstAt.x == coin.x && burstAt.y == coin.y && runtime.effectQueue.isEmpty,
           "a burst after coin.remove() is still at the coin, and checks never fill the real game's queue")
    expect(runtime.checksPlayedSound, "a sound in a check asks the iPad to start its audio early")
    // Clamps: count 0...50 (0 makes nothing), speed 0...30, at most 8 characters.
    s = Functions.none
    s.startPlayer = { p in
        p.burst("🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉", count: 500, speed: 99)
        p.burst("x", count: 0)
        p.burst("", count: 5)
        p.burst("y", count: -3, speed: -4)
    }
    t = drive(".....\n.P...\n#####", s, frames: 2)
    var logged: [Effect] = t.effects.map { $0.effect }
    expect(logged == [.burst(emoji: "🎉🎉🎉🎉🎉🎉🎉🎉", count: 50, speed: 30, x: player.startX, y: player.startY)],
           "burst clamps count to 50, speed to 30 and the emoji to 8 characters; count 0 or no emoji makes nothing (\(logged))")
    // Sounds: at most 16 a frame. Shake strength 1...40.
    s = Functions.none
    s.updatePlayer = { _ in for _ in 0..<40 { game.playSound(.blip) }; game.shake(strength: 99); game.shake(strength: -5) }
    t = drive(".....\n.P...\n#####", s, frames: 3)
    logged = t.effects.map { $0.effect }
    expect(t.sounds.count == 48 && logged.contains(.shake(40)) && logged.contains(.shake(1)),
           "at most 16 sounds a frame (\(t.sounds.count) in 3 frames); shake strength is clamped to 1...40")
    // The real game: effects wait in the queue for the iPad, counted for the harness.
    runtime.testing = false
    game.level = ".....\n.P..F\n#####"
    s = Functions.none
    s.updatePlayer = { p in if p.timer == 0 { game.playSound(.coin); p.burst("✨"); game.shake() }; p.timer += 1 }
    runtime.begin(page: .design, functions: s, runChecks: false)
    runtime.tick(); runtime.tick()
    let taken = runtime.takeEffects()
    expect(taken.count == 3 && runtime.soundsPlayed == 1 && runtime.burstsMade == 1 && runtime.takeEffects().isEmpty,
           "in the real game effects wait in a queue the iPad drains (\(taken.count))")
    for _ in 0..<1000 { game.playSound(.coin); runtime.soundsThisFrame = 0 }
    expect(runtime.effectQueue.count == Runtime.maxQueuedEffects, "an undrained queue keeps only the newest \(Runtime.maxQueuedEffects)")
    runtime.effectQueue = []
    game.level = ""
    runtime.testing = true

    // 17. The synth and mixer: every sound 0.05-1.2 s, peak <= 0.5, no NaN; 8 voices; the same sound
    //     restarts its own voice; the limiter keeps the mix below 1.
    var soundsOK = true
    var lengths: [String] = []
    for sound in GameSound.allCases {
        let samples = Synth.render(sound, rate: 48_000)
        let seconds = Double(samples.count) / 48_000
        let peak = samples.map { abs($0) }.max() ?? 0
        if seconds < 0.05 || seconds > 1.2 || peak > 0.5 || samples.contains(where: { !$0.isFinite }) { soundsOK = false }
        lengths.append(String(format: "%@ %.2fs", "\(sound)", seconds))
    }
    expect(soundsOK && GameSound.allCases.count == 12, "12 sounds, each 0.05-1.2 s long, peak at most 0.5, no NaN (\(lengths.joined(separator: ", ")))")
    expect(Synth.render(.coin, rate: 0).isEmpty && Synth.render(.coin, rate: 44_100).count == Int(0.06 * 44_100) + Int(0.28 * 44_100),
           "a sample rate of 0 renders nothing; any real rate works")
    let mixer = Mixer()
    let buffer = UnsafeMutablePointer<Float>.allocate(capacity: 512)
    defer { buffer.deallocate() }
    mixer.play(.coin)
    mixer.render(into: buffer, count: 512)
    expect((0..<512).allSatisfy { buffer[$0] == 0 }, "with no sounds rendered yet the mixer is silent and drops requests")
    mixer.setBank(SoundBank(rate: 48_000, effects: GameSound.allCases.map { Synth.render($0, rate: 48_000) }))
    for _ in 0..<60 { mixer.play(.coin) }
    mixer.render(into: buffer, count: 512)
    let oneVoice = mixer.activeVoices
    for sound in GameSound.allCases { mixer.play(sound); mixer.play(sound) }
    mixer.render(into: buffer, count: 512)
    var loudest: Float = 0
    for i in 0..<512 { loudest = max(loudest, abs(buffer[i])) }
    expect(oneVoice == 1 && mixer.activeVoices == 8 && loudest < 1 && (0..<512).allSatisfy { buffer[$0].isFinite },
           "a sound played every frame restarts its own voice (\(oneVoice) voice); 12 at once share 8 voices; the limiter keeps the mix below 1 (\(loudest))")
    // game.soundVolume: 0 to 100, 30 at first; 100 is the old loudness (the main mixer at 0.5).
    let startVolume = game.soundVolume
    var volumes: [Int] = []
    for v in [-5, 0, 55, 100, 150, Int.max, Int.min] { game.soundVolume = v; volumes.append(game.soundVolume) }
    let gains = [100, 30, 0, 200, -1].map { Game.mixerVolume($0) }
    expect(startVolume == 30 && volumes == [0, 0, 55, 100, 100, 100, 0] && gains == [0.5, 0.15, 0, 0.5, 0],
           "game.soundVolume starts at 30 and stays 0 to 100 (\(startVolume), \(volumes)); the mixer gets 0.5 x volume / 100 (\(gains))")
    game.soundVolume = 0
    let silentRun = TestDrive(".....\n.P...\n#####", { var q = Functions.none; q.updatePlayer = { _ in game.playSound(.coin) }; return q }())
    silentRun.run(3)
    expect(silentRun.sounds.count == 3, "at volume 0 every sound is still asked for and logged, so the checks are the same (\(silentRun.sounds.count))")
    game.soundVolume = 30

    // 18. Particles, weather and shake (the iPad draws these models).
    var particles = ParticleSystem()
    particles.emit("✨", count: 50, speed: 4, x: 100, y: 100)
    particles.emit("✨", count: 50, speed: 4, x: 100, y: 100)
    particles.emit("✨", count: 50, speed: 4, x: 100, y: 100)
    expect(particles.aliveCount == 100, "at most 100 new particles a step (\(particles.aliveCount))")
    for _ in 0..<4 { particles.step(); for _ in 0..<2 { particles.emit("💥", count: 50, speed: 8, x: 0, y: 0) } }
    expect(particles.aliveCount == ParticleSystem.capacity, "the pool holds 300; when it is full the oldest is recycled (\(particles.aliveCount))")
    for _ in 0..<ParticleSystem.lifetime { particles.step() }
    expect(particles.aliveCount == 0, "every particle fades out in 30 steps")
    particles.emit("+1", count: 1, speed: 0, x: 10, y: 10)
    particles.step(); particles.step()
    let floater = particles.particles.first { $0.alive }!
    expect(floater.x == 10 && floater.y == 12 && floater.scale < 1 && floater.life < 1, "speed 0 floats up 1 point a step, shrinking and fading")
    var weather = WeatherSystem()
    for _ in 0..<50 { weather.step("❄️🍂🍁🌸🌼") }
    let kinds = Set(weather.flakes.filter { $0.alive }.map { $0.emoji })
    expect(weather.aliveCount == 10 && kinds == ["❄️", "🍂", "🍁", "🌸"], "weather: one new emoji every 5 steps, the first 4 take turns (\(weather.aliveCount), \(kinds.sorted()))")
    for _ in 0..<2000 { weather.step("❄️") }
    expect(weather.aliveCount <= WeatherSystem.capacity, "weather never has more than 60 at once (\(weather.aliveCount))")
    for _ in 0..<400 { weather.step("") }
    expect(weather.aliveCount == 0, "weather \"\" stops it, and what is falling falls away")
    var shake = ShakeState()
    shake.start(30)
    var biggest = 0.0
    for _ in 0..<ShakeState.frames { shake.step(); biggest = max(biggest, abs(shake.offset.x), abs(shake.offset.y)) }
    shake.step()
    expect(biggest <= 30 && biggest > 0 && shake.offset.x == 0 && shake.offset.y == 0 && !shake.shaking, "a shake moves at most its strength and is over in 20 frames")

    // 19. Backgrounds: horizonColor is skyColor until set; presets set the sky, horizon, blocks and
    //     their own layers; addLayer ignores repeats and keeps at most 10, clamped.
    let savedSettings = GameSettings()
    game.background = .plain
    game.skyColor = .hex("112233")
    game.horizonSetting = nil
    expect(game.horizonColor == .hex("112233"), "horizonColor is skyColor until it is set")
    game.horizonColor = .hex("ffd194")
    game.skyColor = .white
    expect(game.horizonColor == .hex("ffd194"), "once set, horizonColor stays")
    game.layers = []
    game.background = .night
    expect(game.skyColor == .hex("0b1033") && game.horizonColor == .hex("2e3f7a") && !game.presetLayers.isEmpty && game.layers.isEmpty,
           "game.background = .night sets the sky colors and its own layers (not the page's)")
    var allPresetsOK = true
    for b in GameBackground.allCases {
        game.background = b
        for layer in game.presetLayers where layer.emoji.count > 40 || layer.size < 16 || layer.size > 400 || layer.distance < 1 { allPresetsOK = false }
    }
    expect(GameBackground.allCases.count == 12 && allPresetsOK, "12 presets, every layer within the addLayer limits")
    game.layers = []
    for i in 0..<15 { game.addLayer("🌲 ", y: 64, size: 100, distance: 2 + i) }
    game.addLayer("🌲 ", y: 64, size: 100, distance: 2)
    game.addLayer(String(repeating: "🌳", count: 60), y: 99_999, size: 1, distance: 0)
    expect(game.layers.count == 10, "at most 10 layers of your own; the same call twice adds one (\(game.layers.count))")
    game.layers = []
    game.addLayer(String(repeating: "🌳", count: 60), y: 99_999, size: 1, distance: 0)
    game.addLayer("   ")
    expect(game.layers == [GameLayer(emoji: String(repeating: "🌳", count: 40), y: 2000, size: 16, distance: 1)],
           "addLayer keeps 40 characters, size 16...400, distance 1...50, and ignores a row of spaces (\(game.layers))")
    // Settings come back after the checks and on restart.
    game.background = .sunset
    game.weather = "❄️"
    game.layers = [GameLayer(emoji: "🌲", y: 64, size: 100, distance: 2)]
    let pageSettings = GameSettings()
    game.background = .space
    game.weather = ""
    game.addLayer("🪐", distance: 9)
    pageSettings.apply()
    expect(game.skyColor == GameBackground.sunset.preset.sky && game.backgroundSetting == .sunset && game.weather == "❄️" && game.layers.count == 1
           && game.presetLayers == GameBackground.sunset.preset.layers, "the Settings snapshot puts the background, layers and weather back")
    savedSettings.apply()

    // 20. game.spawn: in order, with its start function first and then the speeds that aren't 0; at
    //     most 50; no spawning inside a spawned thing's start function; gone after an ouch.
    s = Functions.none
    var startOrder: [String] = []
    s.startCrab = { c in startOrder.append("crab \(c.spawned)"); c.speedX = -2; game.spawn(.crab, x: 100, y: 100) }
    s.startFireball = { f in startOrder.append("fireball"); f.speedY = 3 }
    s.updatePlayer = { p in
        if p.timer == 0 {
            game.spawn(.crab, x: 300, y: 88)
            game.spawn(.fireball, x: 200, y: 200, speedX: 12)
            game.spawn(.coin, x: 400, y: 300)
        }
        p.timer += 1
    }
    t = drive("..........\n..........\n..........\n..........\n..........\n.P........\n##########", s, frames: 2)
    let spawnedCrab = t.crabs.first { $0.spawned }
    let fire = t.world.fireballs.first
    expect(startOrder == ["crab true", "fireball"] && t.crabs.count == 1 && t.world.coins.count == 1,
           "spawn calls the start function right away; a spawn inside a spawned thing's start function is ignored (\(startOrder))")
    expect(spawnedCrab?.speedX == -2 && fire?.speedX == 12 && fire?.speedY == 3 && fire?.facingRight() == true,
           "speeds of 0 keep what the start function set; others replace it; a fireball faces the way it flies")
    expect(fire.map { $0.x == 200 + 2 * 12 && $0.y == 200 + 2 * 3 } == true, "a spawned fireball moves by its speeds in the frame it was made, and every frame after")
    // Inside a block: nudged up. Past the edge: kept inside the level.
    s = Functions.none
    s.updatePlayer = { p in if p.timer == 0 { game.spawn(.coin, x: 96, y: 20); game.spawn(.coin, x: -500, y: 300) }; p.timer += 1 }
    t = drive(".....\n.....\n.P...\n#####", s, frames: 1)
    expect(t.world.coins[0].y >= 64 + 24 && t.world.coins[1].x == 24, "a thing spawned inside a block is nudged up; one past the edge stays in the level")
    // The cap: at most 50 alive, the oldest removed.
    s = Functions.none
    s.updatePlayer = { p in for i in 0..<60 { game.spawn(.fireball, x: 100 + i, y: 300) } }
    t = drive("..........\n..........\n..........\n..........\n..........\n.P........\n##########", s, frames: 1)
    expect(t.world.fireballs.count == 50 && t.world.spawnedThings.count == 50 && t.world.fireballs.first?.x == 110,
           "at most 50 spawned things at once: the oldest go first (\(t.world.fireballs.count))")
    // Removed ones leave the arrays at the end of the step; an ouch removes every spawned thing.
    s = Functions.none
    var shot = false
    s.updatePlayer = { p in if !shot { shot = true; game.spawn(.fireball, x: 300, y: 88, speedX: 4); game.spawn(.crab, x: 500, y: 88) }; p.timer += 1; if p.timer == 10 { p.hurt() } }
    s.updateFireball = { f in if f.x > 330 { f.remove() } }
    var counts: [Int] = []
    t = drive("..........\n.P........\n##########", s, frames: 12) { w in counts.append(w.fireballs.count * 10 + w.enemies.count) }
    expect(counts[0] == 11 && counts[8] == 1 && counts[10] == 0 && t.world.spawnedThings.isEmpty,
           "a removed spawned thing leaves the arrays at the end of the step, and an ouch removes every spawned thing (\(counts))")
    // Fireballs never touch the player; they touch enemies.
    s = Functions.none
    var fireHits = 0
    s.updatePlayer = { p in if p.timer == 0 { game.spawn(.fireball, x: p.x, y: p.y, speedX: 5) }; p.timer += 1 }
    s.fireballTouchedEnemy = { f, e in fireHits += 1; e.remove(); f.remove() }
    s.playerTouchedEnemy = { _ in player.hurt() }
    t = drive("..........\n.P.....c..\n##########", s, frames: 100)
    expect(t.world.hurts == 0 && fireHits == 1 && t.crabs[0].removed, "a fireball never hurts the player; fireballTouchedEnemy gets the fireball and the enemy")
    // restart (game over) builds level 1 again: spawned things are gone.
    runtime.testing = false
    game.level = "..........\n.P......F.\n##########"
    s = Functions.none
    s.startGame = { _ in game.spawn(.coin, x: 300, y: 88) }
    runtime.begin(page: .design, functions: s, runChecks: false)
    runtime.tick()
    let before = runtime.realWorld?.coins.count ?? -1
    runtime.realWorld?.coins.first?.remove()
    runtime.restart()
    expect(before == 1 && runtime.realWorld?.coins.count == 0, "restart builds level 1 again, so spawned things are gone")
    runtime.testing = true

    // 21. The ▼ button: asking about .down shows it; justPressed is one frame.
    runtime.usesDown = false
    s = Functions.none
    var downFrames = 0, downHeld = 0
    s.updatePlayer = { _ in if justPressed(.down) { downFrames += 1 }; if isPressed(.down) { downHeld += 1 } }
    t = TestDrive(".....\n.P...\n#####", s)
    t.run(10, hold: [.down])
    t.run(1)
    t.tap(.down, then: 3)
    expect(runtime.usesDown && downFrames == 2 && downHeld == 11, "asking about .down shows the ▼ button; justPressed(.down) is true once per press (\(downFrames)), isPressed every frame held (\(downHeld))")

    // 22. game.nextLevel(): in a check it only counts; in the game it goes to level2, then level3,
    //     keeping the game numbers (startGame doesn't run again), and wins after the last level.
    s = Functions.none
    s.updatePlayer = { p in p.speedX = 6 }
    s.playerTouchedFlag = { game.nextLevel() }
    t = drive("......\n.P..F.\n######", s, frames: 40)
    expect(t.nextLevels > 0 && t.wins == 0, "in a check, game.nextLevel() only counts")
    runtime.testing = false
    game.level = "......\n.P..F.\n######"
    game.level2 = ""
    game.level3 = ".......\n.P..oF.\n#######"
    var gameStarts = 0
    s.startGame = { g in gameStarts += 1; g.score = 7 }
    s.playerTouchedCoin = { c in game.score += 1; c.remove() }
    runtime.begin(page: .design, functions: s, runChecks: false)
    var levels: [Int] = []
    for _ in 0..<200 { runtime.tick(); if levels.last != game.levelNumber { levels.append(game.levelNumber) } }
    expect(levels == [1, 3] && game.score == 8 && gameStarts == 1 && runtime.pageCompleted,
           "nextLevel skips an empty level2, keeps the game numbers (score \(game.score)), never reruns startGame, and wins after the last level (\(levels))")
    expect(runtime.panelLines().contains { $0.contains("Reach the 🚩  (level 2 of 2)") } && runtime.levelCount == 2 && game.levelNumber == 3,
           "the panel counts only levels that have a map: game.levelNumber 3 is level 2 of 2 when level2 is empty")
    runtime.restart()
    expect(game.levelNumber == 1 && game.score == 0, "game over / play again goes back to level 1 with the start numbers")
    game.level = ""; game.level2 = ""; game.level3 = ""
    runtime.pageCompleted = false
    runtime.testing = true
    resetNumbers()

    // 23. Every page's level can be read, has a P and a 🚩, and the Level 2 page's starter map does too.
    for page in GamePage.allCases {
        let map = parseMap(page.info.map)
        expect(map.problems.isEmpty, "\(page.info.title): its level has no map problems \(map.problems)")
    }
    expect(parseMap(Levels.level2Starter).problems.isEmpty && Checks.lettersChanged(Levels.level2Starter, Levels.level2Starter) == 0
           && Checks.lettersChanged(Levels.level2Starter, Levels.level2Starter.replacingOccurrences(of: ".P...#", with: ".Pccc#")) == 3,
           "the Level 2 starter map is clean, and lettersChanged counts changed squares")
    runtime.testing = false
}

// MARK: - Game feel: the jump log, the cool-down, the 🚩 tick, the header's status and "Can't find:"

/// The jump the Coyote Time page teaches, as closures with its own counter (like a page's
/// top-level var). coyote: the window (frames); 0 turns it off.
final class FeelKid {
    var framesInAir = 0
    var coyote = 6
    var updates = 0
    var functions: Functions {
        var s = Functions.none
        s.updatePlayer = { [self] p in
            updates += 1
            if isPressed(.right) { p.speedX = 6 } else if isPressed(.left) { p.speedX = -6 } else { p.speedX = 0 }
            p.speedY -= 1
            if p.isOnGround() { framesInAir = 0 } else { framesInAir += 1 }
            if isPressed(.up) && framesInAir < max(coyote, 1) {
                p.speedY = 18
                framesInAir = max(coyote, 1)
            }
        }
        s.playerTouchedSpring = { _ in player.speedY = 25 }
        s.playerTouchedEnemy = { e in if player.speedY < 0 { e.remove(); player.speedY = 12 } else { player.hurt() } }
        return s
    }
}

func gameFeel() {
    let runtime = Runtime.shared
    runtime.testing = true
    resetNumbers()

    // 25. The jump log: from the ground, a coyote jump, a jump in mid-air, a jump without ▲; a 🍄
    //     bounce and a stomp bounce are not jumps.
    let cliff = "........................\n.P......................\n#####...................\n........................\n........................\n........................\n........................\n########################"
    var kid = FeelKid()
    var t = TestDrive(cliff, kid.functions)
    t.run(5)
    var n = 0
    while player.isOnGround() && n < 60 { t.run(1, hold: [.right]); n += 1 }
    t.run(2, hold: [.right]); t.run(1, hold: [.right, .up]); t.run(1, hold: [.right])
    let coyoteJump = t.world.jumps.last
    expect(t.world.jumps.count == 1 && coyoteJump?.fromGround == false && coyoteJump?.airFrames == 3 && coyoteJump?.secondJump == false,
           "a jump 3 frames after walking off a ledge is logged as coyote time (\(String(describing: coyoteJump)))")
    expect(Runtime.describe(coyoteJump!) == "3 frames after the ledge 🐺 (coyote time)", "the inspector words for it: \(Runtime.describe(coyoteJump!))")
    // A jump from the ground while walking toward the ledge says how early it was.
    func earlyWords(_ k: Int) -> String {
        let k2 = FeelKid()
        let d = TestDrive(cliff, k2.functions)
        d.run(5)
        if k > 1 { d.run(k - 1, hold: [.right]) }
        d.run(1, hold: [.right, .up])
        return d.world.jumps.first.map { Runtime.describe($0) } ?? "no jump"
    }
    let early3 = earlyWords(n - 3), atEdge = earlyWords(n)
    expect(early3 == "from the ground, 3 frames before the edge" && atEdge == "from the ground, at the very edge",
           "a jump walking toward a ledge says how early it was (\(early3); \(atEdge))")
    kid = FeelKid()
    t = TestDrive(".......\n.......\n.......\n.......\n.P.....\n#######", kid.functions)
    t.run(5)
    t.run(1, hold: [.up])                                   // a jump from the ground
    t.run(10)
    let fromGround = t.world.jumps.first
    kid.framesInAir = 0                                      // as if nothing was used up: a jump in mid-air
    t.run(1, hold: [.up])
    t.run(60)
    expect(fromGround?.fromGround == true && fromGround?.framesSinceUp == 0 && Runtime.describe(fromGround!) == "from the ground",
           "a jump from the ground is logged as one (\(String(describing: fromGround)))")
    expect(t.world.jumps.count == 2 && t.world.jumps[1].secondJump && Runtime.describe(t.world.jumps[1]) == "in mid-air!", "a second jump before landing is logged as a jump in mid-air")
    var bouncy = Functions.none
    bouncy.updatePlayer = { p in p.speedY -= 1; if p.isOnGround() { p.speedY = 18 } }
    t = TestDrive(".......\n.......\n.......\n.......\n.P.....\n#######", bouncy)
    t.run(10)
    expect(t.world.jumps.first.map { Runtime.describe($0) } == "from the ground, without ▲!", "a jump with no ▲ held says so (\(t.world.jumps.first.map { Runtime.describe($0) } ?? "no jump"))")
    kid = FeelKid()
    t = TestDrive("............\n............\n............\n............\n............\n.P..s.......\n############", kid.functions)
    t.run(60, hold: [.right])
    expect(t.world.jumps.isEmpty && player.y > 100, "a 🍄 bounce comes from an event, so it is not logged as a jump")
    kid = FeelKid()
    t = TestDrive(".......\n...P...\n.......\n.......\n.......\n..#c#..\n#######", kid.functions)
    t.run(90)
    expect(t.world.jumps.isEmpty && t.crabs[0].removed, "a stomp bounce is not a jump either")
    // No short hop: a quick tap of ▲ jumps as high as holding it.
    func peak(_ k: FeelKid, hold: Int) -> Int {
        let d = TestDrive(".......\n.......\n.......\n.......\n.......\n.P.....\n#######", k.functions)
        d.run(5)
        let floor = player.y
        var top = floor
        d.runPressing(60, keys: { i in i <= hold ? GameKey.up.bit : 0 }) { _ in top = max(top, player.y) }
        return top - floor
    }
    kid = FeelKid()
    let full = peak(kid, hold: 45), tap = peak(kid, hold: 1)
    expect(full == 171 && tap == 171, "a jump of 18 rises 171 points, whether ▲ is held (\(full)) or tapped (\(tap))")

    // 26. The cool-down: while a page's checks run, every drive starts by standing still for 12
    //     frames, so a top-level counter never carries a press from one drive to the next. It runs
    //     once more after the last check (before the level), and never outside the checks.
    kid = FeelKid()
    t = TestDrive(".....\n.P...\n#####", kid.functions)
    t.run(10, hold: [.up])
    let afterJump = kid.framesInAir
    kid.updates = 0
    _ = TestDrive(".....\n.P...\n#####", kid.functions)
    expect(afterJump > 6 && kid.updates == 0 && !TestDrive.coolsDown, "outside the checks a drive starts right away (the counter still says you're in the air: \(afterJump))")
    TestDrive.coolsDown = true
    let cooled = TestDrive(".....\n.P...\n#####", kid.functions)
    TestDrive.coolsDown = false
    let afterCool = kid.framesInAir
    cooled.run(30)
    expect(kid.updates >= 12 + 30 && afterCool == 0 && cooled.world.jumps.isEmpty && cooled.messages.isEmpty && cooled.effects.isEmpty,
           "during the checks a drive starts with 12 frames of standing still: the counter is back to 0 on the ground (\(afterCool))")
    // The cool-down's frames never show up in the game's numbers (a game.timer counted in updatePlayer).
    var counting = Functions.none
    counting.updatePlayer = { _ in game.timer += 1; game.score += 2 }
    game.timer = 7; game.score = 3
    TestDrive.coolsDown = true
    _ = TestDrive(".....\n.P...\n#####", counting)
    TestDrive.coolsDown = false
    expect(game.timer == 7 && game.score == 3 && game.levelNumber == 1, "the cool-down puts the game's numbers back (timer \(game.timer), score \(game.score))")
    resetNumbers()
    // In runChecks: on, one cool-down after the last check, then off.
    runtime.testing = false
    kid = FeelKid()
    kid.framesInAir = 6
    game.level = ""
    runtime.begin(page: .coyote, functions: kid.functions, runChecks: true)
    let checkUpdates = kid.updates
    expect(!TestDrive.coolsDown && kid.framesInAir == 0 && runtime.results.allSatisfy { $0?.passed == true },
           "after the checks the counter is settled and the cool-down is off (all of Coyote Time's checks pass with the closure version)")
    kid.updates = 0
    runtime.begin(page: .coyote, functions: kid.functions, runChecks: false)
    expect(kid.updates == 0 && checkUpdates > 0, "with the checks skipped (Step Through), no function runs before the level")

    // 27. The checklist's 🚩 tick: only when the page's 🚩 event finished the level.
    var s = Functions.none
    s.updatePlayer = { p in p.speedX = 6 }
    s.playerTouchedFlag = { game.showMessage("🪙 3 coins left!") }
    game.level = "..........\n.P...F....\n##########"
    runtime.begin(page: .lockedFlag, functions: s, runChecks: false)
    for _ in 0..<60 { runtime.tick() }
    let messageOnly = runtime.panelLines().contains { $0.hasPrefix("⬜️ Reach the 🚩") } && runtime.realWorld?.flagTouched == true
    s.playerTouchedFlag = { game.win() }
    runtime.begin(page: .lockedFlag, functions: s, runChecks: false)
    for _ in 0..<60 { runtime.tick() }
    expect(messageOnly && runtime.panelLines().contains { $0.hasPrefix("✅ Reach the 🚩") },
           "the panel ticks \"Reach the 🚩\" only when the 🚩 event asks for a win, not when it only shows a message")

    // 28. The header: no hints, a short status, and a "Can't find:" line for each function the engine
    //     can't find (at most 2), right away (checks failing or not).
    s = Functions.none
    s.updatePlayer = { p in p.speedX = 6 }        // walks right, so the Walk checks fail
    s.playerTouchedFlag = builtInFunctions().playerTouchedFlag
    game.level = "..........\n.P...F....\n##########"
    runtime.begin(page: .walk, functions: s, runChecks: true)
    let before = runtime.functionWarning
    let failHint = runtime.firstFailure?.hint ?? ""
    for _ in 0..<60 { runtime.tick() }
    let warning = runtime.functionWarning ?? ""
    let panel = runtime.panelLines()
    expect(before == nil && !failHint.isEmpty && warning == "⚠️ Can't find: `func playerTouchedFlag()`"
           && panel.contains("⚠️ Can't find: func playerTouchedFlag()"),
           "a misspelled playerTouchedFlag is named in the header as soon as the 🚩 does nothing, even while checks fail (\(warning))")
    expect(panel.count == 1 + 3 + 1 + 1 && !panel.joined(separator: " ").contains(String(failHint.prefix(16))),
           "the header shows the title, the 3 checks, the 🚩 row and the warning, and no hint (\(panel))")
    runtime.begin(page: .walk, functions: builtInFunctions(), runChecks: true)
    let rightAway = runtime.checklist().notes.map { $0.text }
    expect(rightAway == ["⚠️ Can't find: `func startPlayer(player: Player)`", "⚠️ Can't find: `func updatePlayer(player: Player)`"] || rightAway == ["⚠️ Can't find: `func updatePlayer(player: Player)`"],
           "a function the checks found missing is named right away, before the first frame, at most 2 lines (\(rightAway))")
    for _ in 0..<5 { runtime.tick() }
    let notes = runtime.checklist().notes.map { $0.text }
    expect(notes == ["⚠️ Can't find: `func startPlayer(player: Player)`", "⚠️ Can't find: `func updatePlayer(player: Player)`"],
           "with every function missing, the header names the first 2 (\(notes))")
    // The inspector's "last jump" line on Coyote Time.
    kid = FeelKid()
    game.level = "..........\n.P........\n##########"
    runtime.begin(page: .coyote, functions: kid.functions, runChecks: false)
    runtime.input.keys = GameKey.up.bit
    runtime.tick()
    runtime.input.keys = 0
    for _ in 0..<5 { runtime.tick() }
    expect(runtime.inspectorLines.last == "last jump: from the ground", "Coyote Time's inspector shows the last jump (\(runtime.inspectorLines))")
    // game.soundVolume is a Setting: the checks, game over and "play again" put the page's own back,
    // so the real game (and its audio) starts at the volume the page's top-level code chose.
    game.level = ""
    game.soundVolume = 60
    var volumeChanges = 0
    s = Functions.none
    s.updatePlayer = { p in p.speedX = 6 }
    s.playerTouchedCoin = { c in volumeChanges += 1; game.soundVolume -= 10; c.remove() }
    runtime.begin(page: .sounds, functions: s, runChecks: true)
    let afterChecks = game.soundVolume
    game.soundVolume = 10
    runtime.restart()
    expect(volumeChanges > 0 && afterChecks == 60 && game.soundVolume == 60,
           "a function that changes game.soundVolume in the checks or in play leaves the page's own volume for the game and after game over (\(volumeChanges) changes, \(afterChecks) after the checks, \(game.soundVolume) after game over)")
    game.soundVolume = 30
    game.level = ""
    runtime.testing = false
    resetNumbers()
}

