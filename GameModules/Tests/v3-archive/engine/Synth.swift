//
//  Synth.swift  (GameAPI: the 12 sound effects, made from math, and the mixer the audio thread runs)
//
//  Platform independent, no AVFoundation: the Mac test harness compiles and tests it (every sound
//  is 0.05-1.2 s long, never louder than 0.5, and has no NaN). Audio.swift (iPad only) plays the
//  mixer through AVAudioEngine. No sound files, so nothing to license or load.
//

import Foundation

enum Wave: Sendable { case square, triangle, sine, noise }

/// One piece of a sound: a wave sliding from f0 to f1 Hz while the volume slides from v0 to v1.
struct Segment: Sendable {
    var wave: Wave
    var f0: Double
    var f1: Double
    var seconds: Double
    var v0: Double = 1
    var v1: Double = 0
    var duty: Double = 0.5
}

extension GameSound {
    /// How each sound is made.
    var recipe: [Segment] {
        switch self {
        case .coin:
            return [Segment(wave: .square, f0: 988, f1: 988, seconds: 0.06, v0: 0.8, v1: 0.8),
                    Segment(wave: .square, f0: 1319, f1: 1319, seconds: 0.28, v0: 0.8, v1: 0)]
        case .jump:
            return [Segment(wave: .square, f0: 280, f1: 720, seconds: 0.16, v0: 0.7, v1: 0.1, duty: 0.25)]
        case .hurt:
            return [Segment(wave: .square, f0: 420, f1: 90, seconds: 0.28, v0: 0.8, v1: 0, duty: 0.5)]
        case .stomp:
            return [Segment(wave: .noise, f0: 3000, f1: 3000, seconds: 0.02, v0: 0.6, v1: 0.2),
                    Segment(wave: .sine, f0: 220, f1: 55, seconds: 0.14, v0: 1, v1: 0)]
        case .powerUp:
            let notes = [523.0, 659, 784, 1047, 1319, 1568]
            return notes.map { Segment(wave: .square, f0: $0, f1: $0, seconds: 0.055, v0: 0.6, v1: 0.45, duty: 0.25) }
                + [Segment(wave: .square, f0: 2093, f1: 2093, seconds: 0.2, v0: 0.5, v1: 0, duty: 0.25)]
        case .win:
            let notes = [523.0, 659, 784]
            return notes.map { Segment(wave: .square, f0: $0, f1: $0, seconds: 0.1, v0: 0.6, v1: 0.5) }
                + [Segment(wave: .square, f0: 1047, f1: 1047, seconds: 0.45, v0: 0.6, v1: 0)]
        case .lose:
            let notes = [392.0, 370, 349]
            return notes.map { Segment(wave: .square, f0: $0, f1: $0, seconds: 0.18, v0: 0.6, v1: 0.45) }
                + [Segment(wave: .square, f0: 330, f1: 300, seconds: 0.55, v0: 0.6, v1: 0)]
        case .laser:
            return [Segment(wave: .square, f0: 1600, f1: 180, seconds: 0.2, v0: 0.6, v1: 0, duty: 0.3)]
        case .explosion:
            return [Segment(wave: .noise, f0: 2400, f1: 80, seconds: 0.55, v0: 1, v1: 0)]
        case .boing:
            return [Segment(wave: .sine, f0: 140, f1: 420, seconds: 0.12, v0: 0.9, v1: 0.8),
                    Segment(wave: .sine, f0: 420, f1: 160, seconds: 0.25, v0: 0.8, v1: 0)]
        case .blip:
            return [Segment(wave: .square, f0: 880, f1: 880, seconds: 0.05, v0: 0.6, v1: 0)]
        case .whoosh:
            return [Segment(wave: .noise, f0: 300, f1: 3000, seconds: 0.18, v0: 0, v1: 0.6),
                    Segment(wave: .noise, f0: 3000, f1: 600, seconds: 0.18, v0: 0.6, v1: 0)]
        }
    }
}

/// A tiny, fast random number generator (the same on every run, so tests are repeatable).
struct Noise {
    var state: UInt32 = 0x9E3779B9
    mutating func next() -> Float {
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        return Float(Int32(bitPattern: state)) / Float(Int32.max)
    }
}

enum Synth {
    /// Renders one sound effect into samples at `rate` samples per second. Never louder than 0.5.
    static func render(_ sound: GameSound, rate: Double) -> [Float] {
        guard rate >= 8000, rate <= 384_000 else { return [] }
        var out: [Float] = []
        var phase = 0.0
        var noise = Noise()
        var held: Float = 0
        var holdPhase = 0.0
        for seg in sound.recipe {
            let n = Int(seg.seconds * rate)
            out.reserveCapacity(out.count + n)
            for i in 0..<n {
                let t = Double(i) / Double(max(n, 1))
                let f = seg.f0 + (seg.f1 - seg.f0) * t
                let v = Float(seg.v0 + (seg.v1 - seg.v0) * t)
                var s: Float
                switch seg.wave {
                case .square:
                    phase += f / rate
                    phase -= phase.rounded(.down)
                    s = phase < seg.duty ? 1 : -1
                case .triangle:
                    phase += f / rate
                    phase -= phase.rounded(.down)
                    s = Float(phase < 0.5 ? 4 * phase - 1 : 3 - 4 * phase)
                case .sine:
                    phase += f / rate
                    phase -= phase.rounded(.down)
                    s = Float(sin(2 * Double.pi * phase))
                case .noise:
                    // Sample-and-hold noise: a lower f sounds deeper (like the NES noise channel).
                    holdPhase += f / rate
                    if holdPhase >= 1 { holdPhase -= holdPhase.rounded(.down); held = noise.next() }
                    s = held
                }
                out.append(max(-0.5, min(0.5, s * v * 0.5)))
            }
        }
        // 3 ms fade-out so nothing clicks.
        let fade = min(out.count, Int(0.003 * rate))
        for i in 0..<fade { out[out.count - 1 - i] *= Float(i) / Float(max(fade, 1)) }
        return out
    }
}

// MARK: - The mixer the audio thread runs (no allocation, no waiting)

/// The rendered sound effects in plain memory, one buffer per GameSound. The main thread builds a
/// new one and swaps it in under the lock; the audio thread only ever *tries* the lock.
final class SoundBank: @unchecked Sendable {
    let rate: Double
    let effects: [UnsafeMutableBufferPointer<Float>]

    init(rate: Double, effects: [[Float]]) {
        self.rate = rate
        self.effects = effects.map { e in
            let p = UnsafeMutableBufferPointer<Float>.allocate(capacity: max(e.count, 1))
            p.initialize(repeating: 0)
            for (i, v) in e.enumerated() { p[i] = v }
            return p
        }
    }
    deinit {
        for e in effects { e.deallocate() }
    }
}

/// 8 voices of sound effects. The same sound requested again restarts its own voice, so a sound
/// played every frame buzzes but uses only 1 voice. A soft limiter keeps the mix below full scale.
final class Mixer: @unchecked Sendable {
    static let voiceCount = 8
    static let maxPending = 16
    private let lock: UnsafeMutablePointer<os_unfair_lock_s>
    // Shared with the main thread (only touched under the lock).
    private var bank: SoundBank?
    private var pendingStarts: [Int32]
    private var pendingCount = 0
    // Audio-thread only.
    private var voiceSound = [Int32](repeating: -1, count: Mixer.voiceCount)
    private var voicePos = [Int](repeating: 0, count: Mixer.voiceCount)
    private var voiceAge = [Int](repeating: 0, count: Mixer.voiceCount)

    init() {
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock_s())
        pendingStarts = [Int32](repeating: -1, count: Mixer.maxPending)
    }
    deinit {
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    // MARK: Main thread

    func setBank(_ b: SoundBank?) {
        os_unfair_lock_lock(lock)
        bank = b
        os_unfair_lock_unlock(lock)
    }
    func play(_ sound: GameSound) {
        os_unfair_lock_lock(lock)
        if pendingCount < pendingStarts.count {
            pendingStarts[pendingCount] = Int32(sound.rawValue)
            pendingCount += 1
        }
        os_unfair_lock_unlock(lock)
    }

    // MARK: Audio thread

    /// Fills `out` with `count` mono samples. Never waits: if the main thread holds the lock, this
    /// buffer is silent (a few milliseconds).
    func render(into out: UnsafeMutablePointer<Float>, count: Int) {
        guard count > 0 else { return }
        for i in 0..<count { out[i] = 0 }
        guard os_unfair_lock_trylock(lock) else { return }
        defer { os_unfair_lock_unlock(lock) }
        guard let b = bank else {
            pendingCount = 0
            return
        }
        // New sounds: the same sound restarts in its own voice; otherwise a free voice; otherwise
        // the oldest voice is reused.
        for k in 0..<pendingCount {
            let s = pendingStarts[k]
            if s < 0 || Int(s) >= b.effects.count { continue }
            var slot = -1
            for v in 0..<Mixer.voiceCount where voiceSound[v] == s { slot = v }
            if slot < 0 { for v in 0..<Mixer.voiceCount where voiceSound[v] < 0 { slot = v; break } }
            if slot < 0 {
                var oldest = 0
                for v in 1..<Mixer.voiceCount where voiceAge[v] > voiceAge[oldest] { oldest = v }
                slot = oldest
            }
            voiceSound[slot] = s
            voicePos[slot] = 0
            voiceAge[slot] = 0
        }
        pendingCount = 0
        for v in 0..<Mixer.voiceCount {
            let idx = Int(voiceSound[v])
            if idx < 0 { continue }
            let buf = b.effects[idx]
            var pos = voicePos[v]
            let n = min(count, buf.count - pos)
            if n > 0, let base = buf.baseAddress {
                let from = base + pos
                for i in 0..<n { out[i] += from[i] }
                pos += n
            }
            if pos >= buf.count { voiceSound[v] = -1 }
            voicePos[v] = pos
            voiceAge[v] += count
        }
        // Soft limiter: stays below 1.0 however many sounds play at once, with no harsh clipping.
        for i in 0..<count {
            let s = out[i]
            out[i] = s.isFinite ? s / (1 + abs(s)) : 0
        }
    }

    /// How many voices are playing (tests).
    var activeVoices: Int { voiceSound.filter { $0 >= 0 }.count }
}
