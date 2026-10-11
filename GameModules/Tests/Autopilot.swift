//
//  Autopilot.swift  (test tool, not shipped in the book)
//  A simple player that presses the game's buttons: head for the flag (or the next coin / crab
//  while the flag is locked), jump at walls, pits, spikes and enemies, wait for low bees. With star
//  power (a ⭐ taken and player.timer > 0) it walks straight through enemies; once a function asks
//  about ▼ it taps ▼ at enemies ahead (and waits for them to go); it follows game.nextLevel().
//

import Foundation

struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x1234567 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class Autopilot {
    var rng: SeededRandom
    var waitFrames = 0
    var escapeFrames = 0
    var escapeDir = 0
    var bestDistance = Int.max
    var sinceProgress = 0
    var lastHurts = 0
    var lastWorld: ObjectIdentifier? = nil
    var frame = 0

    init(seed: UInt64) { rng = SeededRandom(seed: seed) }

    var wantsCoins = false

    func target(_ w: World) -> Thing? {
        let p = player
        if Runtime.shared.message.lowercased().contains("coin") { wantsCoins = true }
        // From Locked Flag on, the page's own 🚩 event waits for every coin: collect them first,
        // like a player who has read the page.
        if [.lockedFlag, .level2, .design].contains(Runtime.shared.page) { wantsCoins = true }
        if w.lock == .coins || wantsCoins, let c = w.coins.filter({ !$0.removed }).min(by: { abs($0.x - p.x) + abs($0.y - p.y) < abs($1.x - p.x) + abs($1.y - p.y) }) {
            return c
        }
        if w.lock == .crabs, let c = w.enemies.filter({ !$0.removed && $0.kind == .crab }).min(by: { abs($0.x - p.x) < abs($1.x - p.x) }) {
            return c
        }
        return w.flags.first { !$0.removed }
    }

    func next(_ w: World) -> Int {
        let L = GameKey.left.bit, R = GameKey.right.bit, U = GameKey.up.bit, D = GameKey.down.bit
        let p = player
        frame += 1
        // A new level (game.nextLevel): start over.
        if lastWorld != ObjectIdentifier(w) {
            lastWorld = ObjectIdentifier(w)
            lastHurts = w.hurts
            bestDistance = Int.max
            sinceProgress = 0
            escapeFrames = 0
            wantsCoins = false
        }
        if w.hurts != lastHurts {
            lastHurts = w.hurts
            waitFrames = Int.random(in: 0..<50, using: &rng)
            bestDistance = Int.max
        }
        if waitFrames > 0 { waitFrames -= 1; return 0 }
        if Int.random(in: 0..<300, using: &rng) == 0 { waitFrames = Int.random(in: 5..<40, using: &rng); return 0 }
        guard let goal = target(w) else { return R }
        let stomping = w.lock == .crabs && goal.kind == .crab

        // Stuck? Run the other way (and jump) for a moment.
        let distance = abs(goal.x - p.x) + abs(goal.y - p.y)
        if distance < bestDistance - 8 { bestDistance = distance; sinceProgress = 0 } else { sinceProgress += 1 }
        if sinceProgress > 150 && escapeFrames == 0 {
            escapeFrames = Int.random(in: 20..<60, using: &rng)
            escapeDir = Bool.random(using: &rng) ? 1 : -1
            sinceProgress = 0
            bestDistance = Int.max
        }
        if escapeFrames > 0 {
            escapeFrames -= 1
            return (escapeDir > 0 ? R : L) | (Bool.random(using: &rng) ? U : 0)
        }

        // A goal more than a jump above: head for a block top to climb on first (a stair).
        let aim = goal.kind.isEnemy ? (x: goal.x, y: goal.y) : (climbStep(w, p, goal) ?? (x: goal.x, y: goal.y))
        let dx = aim.x - p.x
        var dir = dx > 6 ? 1 : (dx < -6 ? -1 : 0)
        var jump = false
        let onGround = p.isOnGround()
        let goalAbove = aim.y - p.y > 40
        // Star power: walk straight through.
        let starPower = p.timer > 0 && w.stars.contains { $0.removed }
        // Fireballs: tap ▼ at an enemy ahead at about the same height, and wait while it's close.
        var fire = false
        if Runtime.shared.usesDown && !starPower {
            let facing = dir != 0 ? dir : (p.facesRight ? 1 : -1)
            if let e = w.enemies.filter({ !$0.removed && abs($0.y - p.y) < 48 && ($0.x - p.x) * facing > 0 && abs($0.x - p.x) < 400 })
                .min(by: { abs($0.x - p.x) < abs($1.x - p.x) }) {
                fire = frame % 8 == 0
                if abs(e.x - p.x) < 150 { dir = 0 }
            }
        }
        if starPower {
            return (dir > 0 ? R : (dir < 0 ? L : 0)) | (fire ? D : 0)
        }

        if onGround {
            if dir != 0 && w.blocked(p, x: p.x + 16 * dir, y: p.y) { jump = true }
            // A pit ahead: nothing solid under a point just past the front edge.
            // v4: a pit with nothing under it (a fall out of the level) is a pit even when the goal is lower.
            if dir != 0 && (!goalBelow(goal, p) || bottomless(w, p.x + (World.half + 18) * dir, p.y)) {
                let probe = p.x + (World.half + 18) * dir
                var floor = false
                var y = p.y - World.half - 2
                while y > p.y - World.half - 3 * tileSize {
                    if spikeAt(w, x: probe, y: y) { break }          // v4: spikes below count as a pit
                    if w.solidPoint(x: probe, y: y) { floor = true; break }
                    y -= 16
                }
                if !floor {
                    // v4: a gap 4 or more squares wide needs the longest jump: wait for the last
                    // frame on the ledge (a human waits for the edge too).
                    if gapWidth(w, p, dir) >= 4 {
                        if !w.blocked(p, x: p.x + 6 * dir, y: p.y - 1) { jump = true }
                    } else {
                        jump = true
                    }
                }
            }
            for s in w.spikes {
                let sx = s.col * tileSize + tileSize / 2
                let sy = (w.rows - 1 - s.row) * tileSize
                if dir != 0 && (sx - p.x) * dir > 0 && (sx - p.x) * dir < 100 && abs(sy - (p.y - World.half)) < 40 { jump = true }
            }
            if goalAbove && abs(dx) < 150 {
                // Don't jump into the underside of the platform the goal sits on.
                if w.solidPoint(x: p.x, y: p.y + World.half + 40) || w.solidPoint(x: p.x + 20 * dir, y: p.y + World.half + 40) {
                    dir = -dir == 0 ? -1 : -dir
                } else {
                    jump = true
                }
            }
            if stomping && abs(dx) < 140 && abs(goal.y - p.y) < 80 { jump = true }
            for e in w.enemies where !e.removed && !(stomping && e === goal) {
                let ahead = (e.x - p.x) * (dir == 0 ? 1 : dir)
                switch e.kind {
                case .crab, .frog, .ghost:
                    if ahead > -10 && ahead < 120 && e.y - p.y < 70 && e.y - p.y > -60 { jump = true }
                case .bee:
                    let rising = e.y > e.y0
                    let low = e.y - p.y < 44 || (!rising && e.y - p.y < 70)
                    if ahead > 30 && ahead < 115 && low { return 0 }        // wait for it to fly up
                default: break
                }
            }
        } else if stomping {
            dir = goal.x > p.x + 4 ? 1 : (goal.x < p.x - 4 ? -1 : 0)
        }
        var bits = dir > 0 ? R : (dir < 0 ? L : 0)
        if jump {
            bits |= U
            // Keep ▲ held while rising, like a person (from v5, when a tap was a short hop; harmless now).
            holdUp = spikesOverhead(w, p, dir) ? 3 : 18
        } else if holdUp > 0 {
            holdUp -= 1
            if !onGround && p.speedY > 0 { bits |= U } else { holdUp = 0 }
        }
        if fire { bits |= D }
        return bits
    }

    var holdUp = 0

    /// The goal is more than a jump above (a coin on a high shelf): a block top 1 to 2 squares above
    /// the feet, with room above it, within 10 squares, the one nearest the goal. nil when the goal
    /// is within a jump, or no such block is nearer the goal than the player is.
    func climbStep(_ w: World, _ p: Thing, _ goal: Thing) -> (x: Int, y: Int)? {
        guard goal.y - p.y > 150 else { return nil }
        let feet = p.y - World.half
        var best: (x: Int, y: Int, score: Int)? = nil
        for row in 1..<w.rows {
            for col in 0..<w.cols where w.tiles[row][col].isSolid {
                if w.tiles[row - 1][col] != .air || (row >= 2 && w.tiles[row - 2][col] != .air) { continue }
                let top = (w.rows - row) * tileSize
                let cx = col * tileSize + tileSize / 2
                if top - feet < 40 || top - feet > 150 || abs(cx - p.x) > 10 * tileSize { continue }
                let score = abs(cx - goal.x) + abs(top + World.half - goal.y)
                if best == nil || score < best!.score { best = (cx, top + World.half, score) }
            }
        }
        guard let b = best, b.score < abs(p.x - goal.x) + abs(p.y - goal.y) else { return nil }
        return (b.x, b.y)
    }

    /// Nothing solid below this point, all the way down (or only spikes): falling here is an ouch.
    func bottomless(_ w: World, _ x: Int, _ y: Int) -> Bool {
        var y = y - World.half - 2
        while y >= 0 {
            if spikeAt(w, x: x, y: y) { return true }
            if w.solidPoint(x: x, y: y) { return false }
            y -= 16
        }
        return true
    }

    func spikeAt(_ w: World, x: Int, y: Int) -> Bool {
        guard x >= 0, y >= 0, x < w.widthInPoints, y < w.heightInPoints else { return false }
        return w.tile(col: x / tileSize, row: w.rows - 1 - y / tileSize) == .spikes
    }

    /// Squares of pit ahead, from the front edge of the ledge (no block within 3 squares below).
    func gapWidth(_ w: World, _ p: Thing, _ dir: Int) -> Int {
        let feet = p.y - World.half - 2
        var col = (p.x + (World.half + 18) * dir) / tileSize
        var n = 0
        while n < 8 {
            let x = col * tileSize + tileSize / 2
            var solid = false
            var y = feet
            while y > feet - 3 * tileSize {
                if spikeAt(w, x: x, y: y) { break }
                if w.solidPoint(x: x, y: y) { solid = true; break }
                y -= 16
            }
            if solid { return n }
            n += 1
            col += dir
        }
        return n
    }

    /// 🌵 hanging over the next 3 squares, within a full jump (200 points) above the head.
    func spikesOverhead(_ w: World, _ p: Thing, _ dir: Int) -> Bool {
        for s in w.spikes {
            let sx = s.col * tileSize + tileSize / 2
            let sb = (w.rows - 1 - s.row) * tileSize
            let ahead = (sx - p.x) * (dir == 0 ? 1 : dir)
            if ahead > -64 && ahead < 3 * tileSize && sb > p.y && sb - p.y < 200 { return true }
        }
        return false
    }

    private func goalBelow(_ goal: Thing, _ p: Thing) -> Bool { goal.y < p.y - 40 }
}
