//
//  ChecksAffordances.swift  (GameAPI: the checks of Coyote Time)
//
//  Every check measures behavior with test drives, never the student's variables (the engine
//  can't see them). The student's top-level vars keep their numbers from drive to drive, so every
//  drive first stands still on the floor until the counters settle.
//  World.jumps logs every frame in which updatePlayer raised speedY above 0 (a jump), with the
//  engine's own counts at that moment.
//

import Foundation

extension Checks {
    // MARK: Shared drives

    /// Stands still until the player has been on the ground for 8 frames in a row (at most 150
    /// frames), so the student's counter (framesInAir) is back to "on the ground".
    static func settle(_ t: TestDrive) {
        var onGround = 0, n = 0
        while onGround < 8 && n < 150 {
            t.run(1)
            onGround = player.isOnGround() ? onGround + 1 : 0
            n += 1
        }
    }

    /// A ledge 14 squares above the floor: walk off it, and the fall lasts about 50 frames.
    static let cliff: String = {
        var rows = [String](repeating: "..............................", count: 2)
        rows.append("..P...........................")
        rows.append("######........................")
        for _ in 0..<14 { rows.append("..............................") }
        rows.append("##############################")
        return rows.joined(separator: "\n")
    }()

    /// Walks off the cliff holding ▶, then taps ▲ on the k-th frame in the air (k = 1 is the first
    /// frame whose update sees isOnGround() false). Did a jump start on that frame or the next two?
    /// Also: how far the player had fallen when ▲ was tapped.
    static func lateTap(_ functions: Functions, k: Int) -> (jumped: Bool, fell: Int, builtIn: Bool, ownJump: Bool) {
        let t = TestDrive(cliff, functions)
        settle(t)
        let ledgeY = player.y
        var n = 0
        while player.isOnGround() && n < 120 { t.run(1, hold: [.right]); n += 1 }
        let walkedOff = t.world.frame
        if k > 1 { t.run(k - 1, hold: [.right]) }
        let fell = ledgeY - player.y
        let pressFrame = t.world.frame + 1
        t.run(1, hold: [.right, .up])
        t.run(2, hold: [.right])
        let jumped = t.world.jumps.contains { $0.frame >= pressFrame && $0.frame <= pressFrame + 2 }
        // A jump with no ▲ at all, while walking or falling (not this check's business, but noted).
        let ownJump = t.world.jumps.contains { $0.frame <= walkedOff + k - 1 && $0.framesSinceUp > 0 }
        return (jumped, fell, t.ranBuiltIn(.updatePlayer), ownJump)
    }

    /// The highest the player gets (above the floor) in `frames` frames, holding ▲ for the first
    /// `hold` of them (hold 1 = a quick tap). Also: the frame it landed again (0 = never), and the
    /// jumps it made (secondJumps: in mid-air).
    static func jumpPeak(_ functions: Functions, hold: Int, frames: Int = 60) -> (peak: Int, landed: Int, jumps: Int, secondJumps: Int, builtIn: Bool) {
        jumpPeak(functions, frames: frames) { i in i <= hold }
    }
    /// The same, with ▲ held on the frames where `up(i)` is true (i = 1 is the first frame).
    static func jumpPeak(_ functions: Functions, frames: Int, up: (Int) -> Bool) -> (peak: Int, landed: Int, jumps: Int, secondJumps: Int, builtIn: Bool) {
        let t = TestDrive(room, functions)
        settle(t)
        let floor = player.y
        let base = t.world.frame
        var peak = floor, landed = 0, wasUp = false
        t.runPressing(frames, keys: { i in up(i) ? GameKey.up.bit : 0 }) { w in
            // The first jump only: its highest point and the frame it lands.
            if landed == 0 { peak = max(peak, player.y) }
            if player.y > floor { wasUp = true }
            if wasUp && landed == 0 && player.isOnGround() { landed = w.frame - base }
        }
        let jumps = t.world.jumps.filter { $0.frame > base }
        return (peak - floor, landed, jumps.count, jumps.filter { $0.secondJump }.count, t.ranBuiltIn(.updatePlayer))
    }

    /// First drive of a page: 60 frames with no button. Any jump?
    static func jumpsByItself(_ functions: Functions) -> (jumped: Bool, firstFrame: Int, builtIn: Bool) {
        let t = TestDrive(room, functions)
        t.run(60)
        return (!t.world.jumps.isEmpty, t.world.jumps.first?.frame ?? 0, t.ranBuiltIn(.updatePlayer))
    }

    static func frames(_ n: Int) -> String { n == 1 ? "1 frame" : "\(n) frames" }

    // ---------- 4. Coyote Time ----------
    static let coyote: [Check] = [
        Check(title: "▲ jumps from the ground") { functions in
            let alone = jumpsByItself(functions)
            if alone.builtIn { return missing(.updatePlayer) }
            if alone.jumped { return "You jumped without pressing ▲. The jump has to stay inside the if that asks about ▲." }
            let tap = jumpPeak(functions, hold: 1)
            if tap.peak >= 40 { return nil }
            return "Pressing ▲ on the floor didn't make you jump. On the ground, framesInAir should be 0, and your jump's if should be true when framesInAir is small."
        },
        Check(title: "A late ▲ still jumps (coyote time)") { functions in
            var window = 0
            for k in 1...3 {
                if lateTap(functions, k: k).jumped { window = k } else { break }
            }
            if window == 3 { return nil }
            if window == 0 {
                // After one jump, can you still jump from the ground? If not, framesInAir is stuck.
                if jumpPeak(functions, hold: 1).peak < 40 {
                    return "After your first jump, ▲ stopped working, even on the ground. framesInAir has to go back to 0 on a block, and go up by 1 every frame in the air."
                }
                return "You ran off a ledge, pressed ▲ 1 frame later, and nothing happened. Make framesInAir count the frames since you left a block, and let your jump ask if it's small."
            }
            return "You can only jump \(frames(window)) after you leave a ledge. That's too short to feel. Real games give about 6 frames (a tenth of a second)."
        },
        Check(title: "No jumping in mid-air") { functions in
            let far = lateTap(functions, k: 30)
            if far.jumped {
                return "You can still jump half a second after leaving a ledge. framesInAir must go up by 1 every frame in the air, and its var must be at the top, outside every function."
            }
            var latest = 0, fell = 0
            for k in [13, 16, 20] {
                let r = lateTap(functions, k: k)
                if r.jumped { latest = k; fell = r.fell }
            }
            if latest == 0 { return nil }
            return "You can still jump \(frames(latest)) after leaving a ledge, after falling \(fell) points: a second jump, not coyote time. Real games give about 6 frames (a tenth of a second)."
        },
        Check(title: "One jump until you land") { functions in
            let tap = jumpPeak(functions, hold: 1)
            let held = jumpPeak(functions, hold: 45, frames: 45)
            if held.builtIn { return missing(.updatePlayer) }
            let twice = jumpPeak(functions, frames: 45) { i in i == 1 || i == 4 }   // a quick double tap
            let apex = jumpPeak(functions, frames: 45) { i in i == 1 || i == 21 }   // again near the top
            if tap.secondJumps + held.secondJumps + twice.secondJumps + apex.secondJumps == 0 { return nil }
            if tap.secondJumps + held.secondJumps + twice.secondJumps == 0 {
                return "Tapping ▲ again at the top of a jump made you jump again in mid-air (\(apex.peak) points high). Let framesInAir decide when you can jump, not your speed, and use it up."
            }
            let how = tap.secondJumps > 0 ? "A tap of ▲" : (held.secondJumps > 0 ? "Holding ▲" : "Tapping ▲ twice quickly")
            let high = max(tap.peak, held.peak, twice.peak)
            return "\(how) jumped again in mid-air (\(high) points high). When you jump, set framesInAir to a number that makes your jump's if false, and count it above the jump."
        },
    ]
}
