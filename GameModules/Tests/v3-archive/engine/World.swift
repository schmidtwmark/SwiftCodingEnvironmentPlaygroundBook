//
//  World.swift  (GameAPI: the level map and one 1/60 s step of the game, platform independent)
//
//  One step: startGame -> start scripts -> update scripts -> physics -> touches -> playerGotHurt
//  -> updateGame. Also player.hurt(), and the test drives each page runs before its level.
//  The iPad renderer (Engine.swift) and the Mac harness both drive exactly this code.
//

import Foundation

// MARK: - Level map

enum Tile: Sendable, Equatable {
    case air, block, brick, spikes
    var isSolid: Bool { self == .block || self == .brick }
}

struct ParsedMap {
    var cols = 0
    var rows = 0
    /// tiles[row][col]; row 0 is the TOP line of the map.
    var tiles: [[Tile]] = []
    /// Things in map order: top to bottom, left to right.
    var placements: [(kind: Kind, col: Int, row: Int)] = []
    var scenery: [(emoji: String, col: Int, row: Int)] = []
    var problems: [String] = []
}

/// Legend: `#` block, `=` brick, `.`/space air, `P` player, `F` flag, `o` coin, `^` spikes,
/// `c` crab, `b` bee, `g` ghost, `f` frog, `s` spring, `*` star, `T` tree, `~` cloud.
func parseMap(_ text: String) -> ParsedMap {
    var map = ParsedMap()
    var lines = text.replacingOccurrences(of: "\r", with: "")
        .split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
    while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty { lines.removeFirst() }
    while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty { lines.removeLast() }
    map.rows = lines.count
    map.cols = lines.map { $0.count }.max() ?? 0
    var unknown: [Character] = []
    var players = 0
    var flags = 0
    for (row, line) in lines.enumerated() {
        var tileRow: [Tile] = []
        for (col, ch) in line.enumerated() {
            var tile = Tile.air
            switch ch {
            case ".", " ", "\t": break
            case "#": tile = .block
            case "=": tile = .brick
            case "^": tile = .spikes
            case "P":
                players += 1
                if players == 1 { map.placements.append((.player, col, row)) }
            case "F":
                flags += 1
                map.placements.append((.flag, col, row))
            case "o": map.placements.append((.coin, col, row))
            case "c": map.placements.append((.crab, col, row))
            case "b": map.placements.append((.bee, col, row))
            case "g": map.placements.append((.ghost, col, row))
            case "f": map.placements.append((.frog, col, row))
            case "s": map.placements.append((.spring, col, row))
            case "*": map.placements.append((.star, col, row))
            case "T": map.scenery.append(("🌳", col, row))
            case "~": map.scenery.append(("☁️", col, row))
            default:
                if !unknown.contains(ch) { unknown.append(ch) }
            }
            tileRow.append(tile)
        }
        while tileRow.count < map.cols { tileRow.append(.air) }
        map.tiles.append(tileRow)
    }
    if map.rows == 0 { map.problems.append("The level map is empty.") }
    if players == 0 && map.rows > 0 {
        map.problems.append("Put a P in the map to show where the player starts.")
        map.placements.insert((.player, 0, 0), at: 0)
    }
    if players > 1 { map.problems.append("The map has \(players) P's. The first one is the start.") }
    if flags == 0 && map.rows > 0 { map.problems.append("Add an F to the map for the 🚩.") }
    for ch in unknown {
        map.problems.append("\(ch == "\"" ? "A quote mark" : "'\(ch)'") isn't in the legend, so it became air.")
    }
    return map
}

enum FlagLock: Sendable { case none, coins, crabs }

// MARK: - World

final class World {
    static let half = 24          // every hitbox is 48 x 48
    static let teleport = 128     // a script move bigger than this is placed directly
    static let maxSweep = 256     // points per axis per frame

    let cols: Int
    let rows: Int
    var tiles: [[Tile]]
    let scripts: Scripts
    let lock: FlagLock
    let problems: [String]
    var enemies: [Enemy] = []     // map order
    var coins: [Coin] = []
    var springs: [Spring] = []
    var stars: [Star] = []
    /// Coins, springs and stars, in map order: no scripts, only a touch event. They move by their
    /// speed too. (A thing added to coins, springs or stars while the game runs goes here as well.)
    var pickups: [Thing] = []
    /// Fireballs, in the order game.spawn made them.
    var fireballs: [Fireball] = []
    /// Everything game.spawn made that is still in the game, oldest first (at most 50).
    var spawnedThings: [Thing] = []
    static let maxSpawned = 50
    /// A spawned thing's start script is running: a game.spawn inside it is ignored.
    var insideSpawnStart = false
    /// game.spawn dropped a removed thing from spawnedThings (or pushed out the oldest), so it is
    /// still in enemies / coins / pickups: prune at the end of the step.
    var pruneDue = false
    /// Goes up whenever a thing joins or leaves the arrays (the iPad adds and drops sprites).
    var thingsVersion = 0
    var flags: [Thing] = []
    var spikes: [(col: Int, row: Int)] = []
    var scenery: [(emoji: String, col: Int, row: Int)]

    /// startGame and updateGame run in this world: the real game, or a test drive made with game: true.
    var runsGameScripts = false
    /// startGame runs at the beginning of the next frame (the game starts, or starts over).
    var startGameDue = false

    var frame = 0
    var blinkFrames = 0
    /// Ouches so far (each player.hurt(), enemy, spike or fall).
    var hurts = 0
    var hurtThisFrame = false
    /// playerGotHurt runs at the end of this frame. Not cleared when a frame starts, so a hurt
    /// between two frames (a check's world.hurt()) runs it at the end of the next one.
    var gotHurtPending = false
    /// playerGotHurt is running: a player.hurt() inside it does nothing.
    var insideGotHurt = false
    /// How many times playerGotHurt ran.
    var gotHurtRuns = 0
    var flagReached = false
    var lockedFlagTouched = false
    /// Frames in which the player jumped: it stood on a block when the frame began and left the
    /// ground going up.
    var takeoffFrames: [Int] = []
    /// Frames in which the player touched a coin.
    var coinTouchFrames: [Int] = []

    var widthInPoints: Int { cols * tileSize }
    var heightInPoints: Int { rows * tileSize }
    /// Ten rows above the top of the map is a ceiling.
    var ceilingY: Int { (rows + 10) * tileSize }

    init(_ map: ParsedMap, scripts: Scripts, lock: FlagLock) {
        cols = max(map.cols, 1)
        rows = max(map.rows, 1)
        var grid = map.tiles
        if grid.isEmpty { grid = [[.air]] }
        tiles = grid
        self.scripts = scripts
        self.lock = lock
        problems = map.problems
        scenery = map.scenery
        for (row, line) in grid.enumerated() {
            for (col, tile) in line.enumerated() where tile == .spikes { spikes.append((col, row)) }
        }
        for p in map.placements {
            let x = p.col * tileSize + tileSize / 2
            let bottom = (rows - 1 - p.row) * tileSize
            let y = p.kind.startsOnFloor ? bottom + World.half : bottom + tileSize / 2
            let thing = p.kind == .player ? player : World.make(p.kind)
            thing.x = x; thing.y = y; thing.x0 = x; thing.y0 = y
            thing.startX = x; thing.startY = y
            thing.speedX = 0; thing.speedY = 0; thing.timer = 0
            thing.removed = false
            thing.lastFacedRight = (p.kind == .player)
            thing.world = self
            thing.grounded = p.kind.usesBlocks && blocked(thing, x: x, y: y - 1)
            // The player's and each enemy's start script run at the beginning of the first frame.
            thing.needsStart = p.kind == .player || p.kind.isEnemy
            join(thing)
        }
    }

    /// A new thing of that kind, with its starting look from Settings.
    static func make(_ kind: Kind) -> Thing {
        switch kind {
        case .player: return player
        case .crab: let t = Crab(); t.emoji = game.crabEmoji; return t
        case .bee: let t = Bee(); t.emoji = game.beeEmoji; return t
        case .ghost: let t = Ghost(); t.emoji = game.ghostEmoji; return t
        case .frog: let t = Frog(); t.emoji = game.frogEmoji; return t
        case .coin: let t = Coin(); t.emoji = game.coinEmoji; return t
        case .flag: let t = Flag(); t.emoji = game.flagEmoji; return t
        case .spring: let t = Spring(); t.emoji = game.springEmoji; return t
        case .star: let t = Star(); t.emoji = game.starEmoji; return t
        case .fireball: let t = Fireball(); t.emoji = game.fireballEmoji; return t
        }
    }

    /// Puts a thing in the arrays its kind belongs to.
    private func join(_ thing: Thing) {
        if thing.kind.isPickup { pickups.append(thing) }
        switch thing {
        case let coin as Coin: coins.append(coin)
        case let enemy as Enemy: enemies.append(enemy)
        case let spring as Spring: springs.append(spring)
        case let star as Star: stars.append(star)
        case let fireball as Fireball: fireballs.append(fireball)
        default: if thing.kind == .flag { flags.append(thing) }
        }
    }

    // MARK: game.spawn (Unity's Instantiate)

    /// Makes a thing with its middle at x, y (nudged up out of a block), runs its start script, then
    /// gives it the speeds that aren't 0. At most 50 spawned things at once: the oldest goes first.
    func spawn(_ kind: Kind, x: Int, y: Int, speedX: Int, speedY: Int) {
        if insideSpawnStart || kind == .player || kind == .flag { return }
        let thing = World.make(kind)
        thing.world = self
        thing.spawned = true
        thing.x = max(World.half, min(max(World.half, widthInPoints - World.half), clamp(x)))
        thing.y = min(clamp(y), ceilingY - World.half)
        if kind.usesBlocks { nudgeUp(thing) }
        thing.x0 = thing.x; thing.y0 = thing.y
        thing.startX = thing.x; thing.startY = thing.y
        thing.lastFacedRight = speedX > 0
        thing.grounded = kind.usesBlocks && blocked(thing, x: thing.x, y: thing.y - 1)
        let before = spawnedThings.count
        spawnedThings.removeAll { $0.removed }
        if spawnedThings.count != before { pruneDue = true }
        if spawnedThings.count >= World.maxSpawned {
            spawnedThings.removeFirst().removed = true
            pruneDue = true
        }
        spawnedThings.append(thing)
        join(thing)
        thingsVersion += 1
        insideSpawnStart = true
        if let enemy = thing as? Enemy {
            scripts.start(enemy)
        } else if let fireball = thing as? Fireball {
            scripts.startFireball(fireball)
        }
        insideSpawnStart = false
        if speedX != 0 { thing.speedX = clamp(speedX) }
        if speedY != 0 { thing.speedY = clamp(speedY) }
        face(thing)
    }

    /// Takes spawned things that were removed out of the arrays.
    func pruneSpawned() {
        guard pruneDue || spawnedThings.contains(where: { $0.removed }) || fireballs.contains(where: { $0.removed }) else { return }
        pruneDue = false
        func keep(_ t: Thing) -> Bool { !(t.spawned && t.removed) }
        enemies = enemies.filter(keep)
        coins = coins.filter(keep)
        springs = springs.filter(keep)
        stars = stars.filter(keep)
        pickups = pickups.filter(keep)
        fireballs = fireballs.filter(keep)
        spawnedThings = spawnedThings.filter(keep)
        thingsVersion += 1
    }

    /// Every spawned thing disappears (after an ouch).
    func removeSpawned() {
        if spawnedThings.isEmpty && fireballs.isEmpty { return }
        for t in spawnedThings { t.removed = true }
        for f in fireballs { f.removed = true }
        pruneSpawned()
    }


    // MARK: Blocks

    func tile(col: Int, row: Int) -> Tile {
        guard row >= 0, row < rows, col >= 0, col < cols else { return .air }
        return tiles[row][col]
    }

    /// Is the point inside a block? The left and right edges of the level count as walls.
    func solidPoint(x: Int, y: Int) -> Bool {
        if x < 0 || x >= widthInPoints || y >= ceilingY { return true }
        if y < 0 || y >= heightInPoints { return false }
        return tile(col: x / tileSize, row: rows - 1 - y / tileSize).isSolid
    }

    /// Would a 48 x 48 box centered at (x, y) overlap a block?
    func blocked(_ thing: Thing, x: Int, y: Int) -> Bool {
        let left = x - World.half, right = x + World.half - 1
        let bottom = y - World.half, top = y + World.half - 1
        if left < 0 || right >= widthInPoints || top >= ceilingY { return true }
        if top < 0 || bottom >= heightInPoints { return false }
        let c0 = left / tileSize, c1 = right / tileSize
        let rowTop = rows - 1 - min(top, heightInPoints - 1) / tileSize
        let rowBottom = rows - 1 - max(bottom, 0) / tileSize
        for row in rowTop...rowBottom {
            for col in c0...c1 where tiles[row][col].isSolid { return true }
        }
        return false
    }

    // MARK: One step (1/60 s)

    func step() {
        // 1. Count the frame, clear this frame's texts, and count down the blink.
        frame += 1
        Runtime.shared.texts.removeAll()
        Runtime.shared.soundsThisFrame = 0
        hurtThisFrame = false
        if blinkFrames > 0 { blinkFrames -= 1 }

        // 2. The game's start script: when the game starts, and again when it starts over.
        if runsGameScripts && startGameDue {
            startGameDue = false
            scripts.startGame(game)
        }

        // 3. Start scripts (Unity's Start): when the level starts, and again after an ouch put
        // everything back. The player first, then every enemy in map order. They run before this
        // frame's positions are remembered, so a start script that sets x or y just puts it there.
        // (Spawned things already got theirs when they were made.)
        if player.needsStart {
            player.needsStart = false
            scripts.startPlayer(player)
        }
        for e in enemies where e.needsStart && !e.removed {
            e.needsStart = false
            scripts.start(e)
        }

        // 4. Remember where everything was before the update scripts.
        let wasOnGround = player.grounded
        player.x0 = player.x; player.y0 = player.y
        for e in enemies where !e.removed { e.x0 = e.x; e.y0 = e.y }
        for f in fireballs where !f.removed { f.x0 = f.x; f.y0 = f.y }
        for t in pickups where !t.removed { t.x0 = t.x; t.y0 = t.y }

        // 5. Update scripts (Unity's Update): the player, enemies in map order, then fireballs in
        // the order they were made. A script that calls player.hurt() puts everything back, and a
        // thing that was put back waits for its start script (next frame) before it updates again,
        // so Start always comes before Update.
        if !player.needsStart { scripts.updatePlayer(player) }
        for e in enemies where !e.removed && !e.needsStart {
            scripts.update(e)
        }
        for f in fireballs where !f.removed {
            scripts.updateFireball(f)
        }

        // 6. Keep every number far from Int overflow.
        clampNumbers(player)
        for t in enemies { clampNumbers(t) }
        for t in fireballs { clampNumbers(t) }
        for t in pickups { clampNumbers(t) }

        // 7. Physics: one rule for every thing.
        move(player)
        for e in enemies where !e.removed { move(e) }
        for f in fireballs where !f.removed { move(f) }
        for t in pickups where !t.removed && (t.speedX != 0 || t.speedY != 0 || t.x != t.x0 || t.y != t.y0) { move(t) }
        if wasOnGround && !hurtThisFrame && !player.grounded && player.speedY > 0 { takeoffFrames.append(frame) }

        // 8. Falling out of the level.
        if player.y < -2 * tileSize { hurt() }
        for e in enemies where !e.removed && e.y < -2 * tileSize { e.removed = true }
        for f in fireballs where !f.removed && f.y < -2 * tileSize { f.removed = true }
        for t in pickups where !t.removed && t.y < -2 * tileSize { t.removed = true }

        // 9. Touches.
        if !hurtThisFrame { touches() }

        // 10. One playerGotHurt for the ouch (or ouches) of this frame.
        if gotHurtPending {
            gotHurtPending = false
            insideGotHurt = true
            gotHurtRuns += 1
            scripts.playerGotHurt()
            insideGotHurt = false
        }

        // 11. The game's update script, last, so it sees this frame's final numbers.
        if runsGameScripts { scripts.updateGame(game) }

        // 12. Keep the game numbers far from Int overflow.
        game.score = clamp(game.score)
        game.deaths = clamp(game.deaths)
        game.lives = clamp(game.lives)
        game.timer = clamp(game.timer)

        // 13. Spawned things that were removed leave the arrays.
        pruneSpawned()
    }

    func clamp(_ n: Int) -> Int { max(-1_000_000, min(1_000_000, n)) }
    private func clampNumbers(_ t: Thing) {
        t.x = clamp(t.x); t.y = clamp(t.y)
        t.speedX = clamp(t.speedX); t.speedY = clamp(t.speedY)
        t.timer = clamp(t.timer)
    }

    func move(_ t: Thing) {
        let scriptDX = t.x - t.x0, scriptDY = t.y - t.y0
        if !t.kind.usesBlocks {
            // Ghosts float through blocks.
            t.x += t.speedX
            t.y += t.speedY
            t.x = max(World.half, min(max(World.half, widthInPoints - World.half), t.x))
            t.y = min(t.y, ceilingY - World.half)
            t.grounded = false
            face(t)
            return
        }
        // A script that changed x or y by up to 2 squares moved it: blocks still stop it. Further
        // than that, the script put it somewhere on purpose.
        var dx = t.speedX, dy = t.speedY
        if abs(scriptDX) > World.teleport || abs(scriptDY) > World.teleport {
            // The script put it somewhere on purpose: place it there, then apply its speed.
            t.x = max(World.half, min(max(World.half, widthInPoints - World.half), t.x))
            t.y = min(t.y, ceilingY - World.half)
            nudgeUp(t)
        } else {
            dx += scriptDX
            dy += scriptDY
            t.x = t.x0
            t.y = t.y0
            if blocked(t, x: t.x, y: t.y) { nudgeUp(t) }
        }
        // Sweep sideways one point at a time, then up/down. Bumping a wall stops the thing but
        // keeps its speedX (so a script can flip it).
        let stepX = dx > 0 ? 1 : -1
        var n = min(abs(dx), World.maxSweep)
        while n > 0 {
            if blocked(t, x: t.x + stepX, y: t.y) { break }
            t.x += stepX
            n -= 1
        }
        let stepY = dy > 0 ? 1 : -1
        n = min(abs(dy), World.maxSweep)
        while n > 0 {
            if blocked(t, x: t.x, y: t.y + stepY) { t.speedY = 0; break }   // landed, or bumped its head
            t.y += stepY
            n -= 1
        }
        t.grounded = blocked(t, x: t.x, y: t.y - 1)
        face(t)
    }

    /// It faces the way its speedX points. While speedX is 0 it keeps facing the way it last moved.
    func face(_ t: Thing) {
        if t.speedX > 0 { t.lastFacedRight = true }
        if t.speedX < 0 { t.lastFacedRight = false }
    }

    private func nudgeUp(_ t: Thing) {
        var lift = 0
        while blocked(t, x: t.x, y: t.y) && lift < 12 * tileSize {
            t.y += 1
            lift += 1
        }
    }

    // MARK: Touches (every frame two things overlap, like OnTriggerStay)

    func overlap(_ a: Thing, _ b: Thing, _ reach: Int) -> Bool {
        abs(a.x - b.x) < reach && abs(a.y - b.y) < reach
    }

    var lockMessage: String? {
        switch lock {
        case .none: return nil
        case .coins: return coins.contains { !$0.removed } ? "Collect every coin first" : nil
        case .crabs: return enemies.contains { $0.kind == .crab && !$0.removed } ? "Squish every crab first" : nil
        }
    }

    func touchingSpikes() -> Bool {
        let left = player.x - World.half, right = player.x + World.half - 1
        let bottom = player.y - World.half, top = player.y + World.half - 1
        for s in spikes {
            let sl = s.col * tileSize + 4, sr = s.col * tileSize + tileSize - 5
            let sb = (rows - 1 - s.row) * tileSize, st = sb + 31
            if left <= sr && right >= sl && bottom <= st && top >= sb { return true }
        }
        return false
    }

    private func touches() {
        // Coins, springs and stars (reach 40).
        for c in coins where !c.removed && overlap(player, c, 40) {
            if coinTouchFrames.last != frame { coinTouchFrames.append(frame) }
            scripts.playerTouchedCoin(c)
            if hurtThisFrame { return }
        }
        for s in springs where !s.removed && overlap(player, s, 40) {
            scripts.playerTouchedSpring(s)
            if hurtThisFrame { return }
        }
        for s in stars where !s.removed && overlap(player, s, 40) {
            scripts.playerTouchedStar(s)
            if hurtThisFrame { return }
        }
        // Enemies (reach 48) and spikes, unless the player is blinking.
        if blinkFrames == 0 {
            for e in enemies where !e.removed && overlap(player, e, 48) {
                scripts.playerTouchedEnemy(e)
                if hurtThisFrame { return }
            }
            if touchingSpikes() {
                hurt()
                return
            }
        }
        // Fireballs against enemies (reach 48). Fireballs never touch the player.
        for f in fireballs where !f.removed {
            for e in enemies where !e.removed && !f.removed && overlap(f, e, 48) {
                scripts.fireballTouchedEnemy(f, e)
                if hurtThisFrame { return }
            }
        }
        // The flag (reach 56), unless the page's lock holds it.
        for f in flags where !f.removed && overlap(player, f, 56) {
            if let message = lockMessage {
                lockedFlagTouched = true
                Runtime.shared.engineMessage(message)
            } else {
                flagReached = true
                scripts.playerTouchedFlag()
                if hurtThisFrame { return }
            }
        }
    }

    // MARK: Hurt and remove

    /// Ouch: everything back to the start, and playerGotHurt runs at the end of the frame.
    /// Inside playerGotHurt it does nothing.
    func hurt() {
        if insideGotHurt { return }
        hurts += 1
        hurtThisFrame = true
        gotHurtPending = true
        // Spawned things disappear; the map's things go back to their starts.
        removeSpawned()
        reset(player)
        for e in enemies where !e.removed { reset(e) }
        blinkFrames = 60
        Runtime.shared.playerWasHurt()
    }

    /// Back to the start: speeds and timer 0, facing its starting way, and its start script runs
    /// again at the beginning of the next frame.
    private func reset(_ t: Thing) {
        t.x = t.startX; t.y = t.startY
        t.x0 = t.x; t.y0 = t.y
        t.speedX = 0; t.speedY = 0; t.timer = 0
        t.lastFacedRight = (t.kind == .player)
        t.grounded = t.kind.usesBlocks && blocked(t, x: t.x, y: t.y - 1)
        t.needsStart = true
    }

    func remove(_ t: Thing) {
        t.removed = true
    }
}

// MARK: - Test drives

/// A throwaway level for a check. It runs the SAME step() as the game, and logs what the student's
/// code showed. Without `game: true`, startGame and updateGame don't run, so a student's UI code can
/// never break an older check.
final class TestDrive {
    let world: World
    /// What showText showed, frame by frame: texts[0] is frame 1.
    private(set) var texts: [[String]] = []
    /// What the scripts showed with game.showMessage, and in which frame.
    var messages: [(frame: Int, text: String)] = []
    /// game.win(), game.lose() and game.nextLevel() calls during this drive.
    var wins = 0
    var loses = 0
    var nextLevels = 0
    /// Sounds, bursts and shakes the scripts asked for, with the frame and the thing that made a
    /// burst (nil for the game's own effects).
    var effects: [(frame: Int, effect: Effect, source: ObjectIdentifier?)] = []

    init(_ map: String, _ scripts: Scripts, lock: FlagLock = .none, game gameScripts: Bool = false) {
        world = World(parseMap(map), scripts: scripts, lock: lock)
        world.runsGameScripts = gameScripts
        world.startGameDue = gameScripts
        let runtime = Runtime.shared
        runtime.world = world
        runtime.drive = self
        runtime.builtInsRun = 0
        // No button is "already held" from the last drive, so the first press is a justPressed.
        runtime.input.now = 0
        runtime.input.before = 0
    }

    /// Did the engine have to use this built-in script since the drive began? (The page's
    /// function is missing or its first line is different.) Ask before starting the next drive.
    func ranBuiltIn(_ script: ScriptName) -> Bool {
        Runtime.shared.builtInsRun & script.bit != 0
    }

    func run(_ frames: Int, hold: [GameKey] = [], each: (World) -> Void = { _ in }) {
        var bits = 0
        for key in hold { bits |= key.bit }
        runPressing(frames, keys: { _ in bits }, each: each)
    }

    /// Presses `key` for one frame, then lets go for `then` frames (justPressed sees one press).
    func tap(_ key: GameKey, then frames: Int = 1, each: (World) -> Void = { _ in }) {
        run(1, hold: [key], each: each)
        if frames > 0 { run(frames, each: each) }
    }

    /// Runs `frames` frames, with the buttons `keys(i)` held in the i-th of them (from 1).
    func runPressing(_ frames: Int, keys: (Int) -> Int, each: (World) -> Void = { _ in }) {
        let runtime = Runtime.shared
        runtime.world = world
        runtime.drive = self
        for i in 0..<frames {
            runtime.input.test = keys(i + 1)
            runtime.input.beginStep(testing: true)
            Watchdog.shared.enter()
            world.step()
            Watchdog.shared.leave()
            runtime.input.endStep()
            texts.append(runtime.texts)
            each(world)
        }
        runtime.input.test = 0
    }

    /// The texts frame `frame` showed (1 = the first frame of the drive).
    func shown(inFrame frame: Int) -> [String] {
        frame >= 1 && frame <= texts.count ? texts[frame - 1] : []
    }

    /// Did frame `frame` show a text with the whole number `n` in it? 38 doesn't match 138 or 380.
    func shows(_ n: Int, inFrame frame: Int) -> Bool {
        shown(inFrame: frame).contains { wholeNumbers(in: $0).contains(n) }
    }

    /// Did a message (game.showMessage) have the whole number `n` in it?
    func messaged(_ n: Int) -> Bool {
        messages.contains { wholeNumbers(in: $0.text).contains(n) }
    }

    /// The sounds the scripts played, frame by frame.
    var sounds: [(frame: Int, sound: GameSound)] {
        effects.compactMap { e in if case .sound(let s) = e.effect { return (e.frame, s) } else { return nil } }
    }
    /// The frames in which `thing` made a burst.
    func bursts(by thing: Thing) -> [Int] {
        let id = ObjectIdentifier(thing)
        return effects.compactMap { e in
            if case .burst = e.effect, e.source == id { return e.frame } else { return nil }
        }
    }
    /// Every burst: its frame and the thing that made it.
    var allBursts: [(frame: Int, source: ObjectIdentifier?)] {
        effects.compactMap { e in if case .burst = e.effect { return (e.frame, e.source) } else { return nil } }
    }
    /// The fireballs that are in the game right now.
    var fireballs: [Fireball] { world.fireballs.filter { !$0.removed } }

    var crabs: [Crab] { world.enemies.compactMap { $0 as? Crab } }
    var bees: [Bee] { world.enemies.compactMap { $0 as? Bee } }
    var ghosts: [Ghost] { world.enemies.compactMap { $0 as? Ghost } }
    var frogs: [Frog] { world.enemies.compactMap { $0 as? Frog } }
}

/// The whole numbers written in a text: "⭐ 38 / -5" has 38 and -5.
func wholeNumbers(in text: String) -> [Int] {
    var numbers: [Int] = []
    var digits = ""
    var negative = false
    var previous: Character = " "
    func finish() {
        if let n = Int(digits) { numbers.append(negative ? -n : n) }
        digits = ""
        negative = false
    }
    for ch in text {
        if ch.isASCII && ch.isNumber {
            if digits.isEmpty { negative = previous == "-" }
            digits.append(ch)
        } else if !digits.isEmpty {
            finish()
        }
        previous = ch
    }
    if !digits.isEmpty { finish() }
    return numbers
}
