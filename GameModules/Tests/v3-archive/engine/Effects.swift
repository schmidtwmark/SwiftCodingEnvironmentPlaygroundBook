//
//  Effects.swift  (GameAPI: sounds, bursts and shakes the scripts ask for, and the platform-
//  independent models the iPad draws them with: particles, falling weather and the screen shake)
//
//  A script never draws or plays anything itself: game.playSound, thing.burst and game.shake each
//  make an Effect. While a check runs, the check's test drive logs it (so a muted iPad passes the
//  same checks); in the real game it goes into Runtime.effectQueue, which the iPad drains after
//  every step (Engine.swift). The Mac harness counts them.
//

import Foundation

/// Something a script asked for that isn't part of the game's numbers.
enum Effect: Equatable, Sendable {
    case sound(GameSound)
    /// `count` emoji fly out from (x, y), each `speed` points a frame.
    case burst(emoji: String, count: Int, speed: Int, x: Int, y: Int)
    case shake(Int)
}

extension Thing {
    /// A burst of emoji that fly out from this thing and fade in half a second (30 frames):
    /// `coin.burst("✨")`. count: 1 to 50. speed: how far each one flies every frame (0 = it floats
    /// up and fades).
    public func burst(_ emoji: String, count: Int = 8, speed: Int = 4) {
        let n = max(0, min(50, count))
        if n == 0 || emoji.isEmpty { return }
        Runtime.shared.request(.burst(emoji: String(emoji.prefix(8)), count: n, speed: max(0, min(30, speed)), x: x, y: y),
                               source: self)
    }
}

/// A small, fast random number generator for the effects (they never touch the game's numbers).
struct EffectRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64 = 0x2545F4914F6CDD1D) { state = seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    /// A number from 0 up to (not including) 1.
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

// MARK: - Particles (thing.burst)

/// One flying emoji of a burst, in level points.
struct Particle {
    var x = 0.0, y = 0.0, vx = 0.0, vy = 0.0
    var age = 0
    var emoji = ""
    var alive = false
    /// 1 when it starts, 0 when it's gone.
    var life: Double { 1 - Double(age) / Double(ParticleSystem.lifetime) }
    /// It shrinks from 100% to 40% as it fades.
    var scale: Double { 0.4 + 0.6 * life }
}

/// A fixed pool of particles. Every particle lives the same 30 frames, so the slot written next is
/// always the oldest one: when the pool is full, the oldest is recycled.
struct ParticleSystem {
    static let capacity = 300
    static let maxNewPerFrame = 100
    static let lifetime = 30
    private(set) var particles = [Particle](repeating: Particle(), count: ParticleSystem.capacity)
    private var nextSlot = 0
    private var newThisStep = 0
    private var random = EffectRandom()

    var aliveCount: Int { particles.reduce(0) { $0 + ($1.alive ? 1 : 0) } }

    /// Evenly spaced directions with a little jitter, each at about `speed` points a frame.
    mutating func emit(_ emoji: String, count: Int, speed: Int, x: Int, y: Int) {
        let n = min(count, ParticleSystem.maxNewPerFrame - newThisStep)
        if n <= 0 { return }
        newThisStep += n
        let turn = random.unit() * 2 * Double.pi
        for i in 0..<n {
            let angle = turn + 2 * Double.pi * Double(i) / Double(n) + (random.unit() - 0.5) * 0.6 / Double(max(n, 1))
            let v = Double(speed) * (0.85 + 0.3 * random.unit())
            particles[nextSlot] = Particle(x: Double(x), y: Double(y), vx: cos(angle) * v, vy: sin(angle) * v,
                                           age: 0, emoji: emoji, alive: true)
            nextSlot = (nextSlot + 1) % ParticleSystem.capacity
        }
    }

    /// One fixed step: every particle flies, drifts 1 point up, and ages one frame.
    mutating func step() {
        newThisStep = 0
        for i in particles.indices where particles[i].alive {
            particles[i].x += particles[i].vx
            particles[i].y += particles[i].vy + 1
            particles[i].age += 1
            if particles[i].age >= ParticleSystem.lifetime { particles[i].alive = false }
        }
    }

    mutating func clear() {
        for i in particles.indices { particles[i].alive = false }
    }
}

// MARK: - Weather (game.weather)

/// One falling emoji, in screen points (0, 0 is the bottom left of the 1024 x 576 screen).
struct Flake {
    var x = 0.0, y = 0.0, speed = 2.0, phase = 0.0
    var emoji = ""
    var alive = false
    /// Sideways sway around x.
    var drawX: Double { x + 14 * sin(phase) }
}

/// Emoji falling from the top of the screen: a new one every 5 frames, 60 at most.
struct WeatherSystem {
    static let capacity = 60
    static let every = 5
    static let width = 1024.0, height = 576.0
    private(set) var flakes = [Flake](repeating: Flake(), count: WeatherSystem.capacity)
    private var frame = 0
    private var turn = 0
    private var random = EffectRandom(seed: 0x9E3779B97F4A7C15)

    var aliveCount: Int { flakes.reduce(0) { $0 + ($1.alive ? 1 : 0) } }

    /// One fixed step. `emoji` is game.weather: its first 4 characters take turns ("" makes no new ones).
    mutating func step(_ emoji: String) {
        frame += 1
        for i in flakes.indices where flakes[i].alive {
            flakes[i].y -= flakes[i].speed
            flakes[i].phase += 0.05
            if flakes[i].y < -40 { flakes[i].alive = false }
        }
        let kinds = Array(emoji.filter { !$0.isWhitespace }.prefix(4)).map { String($0) }
        guard !kinds.isEmpty, frame % WeatherSystem.every == 0,
              let slot = flakes.firstIndex(where: { !$0.alive }) else { return }
        flakes[slot] = Flake(x: random.unit() * WeatherSystem.width, y: WeatherSystem.height + 30,
                             speed: 2 + random.unit(), phase: random.unit() * 6.28,
                             emoji: kinds[turn % kinds.count], alive: true)
        turn += 1
    }

    mutating func clear() {
        for i in flakes.indices { flakes[i].alive = false }
    }
}

// MARK: - Screen shake (game.shake)

/// A shake moves the level and the background (never the text) by a random amount that fades
/// out over 20 frames.
struct ShakeState {
    static let frames = 20
    private var strength = 0
    private var left = 0
    private var random = EffectRandom(seed: 0xD1B54A32D192ED03)
    private(set) var offset = (x: 0.0, y: 0.0)

    var shaking: Bool { left > 0 }

    mutating func start(_ s: Int) {
        // A stronger shake takes over; a weaker one doesn't cut a strong one short.
        if left == 0 || s >= strength * left / ShakeState.frames {
            strength = max(1, min(40, s))
            left = ShakeState.frames
        }
    }

    mutating func step() {
        guard left > 0 else { offset = (0, 0); return }
        let amount = Double(strength) * Double(left) / Double(ShakeState.frames)
        offset = ((random.unit() * 2 - 1) * amount, (random.unit() * 2 - 1) * amount)
        left -= 1
    }

    mutating func clear() { left = 0; offset = (0, 0) }
}
