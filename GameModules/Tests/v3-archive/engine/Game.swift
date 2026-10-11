//
//  Game.swift  (GameAPI: `game`, its numbers, calls and Settings, colors, sounds, backgrounds,
//  and the friendly errors)
//
//  Platform independent (the Mac test harness compiles it too).
//

import Foundation

/// The game itself. There is exactly one: `game` (it works in every script).
public final class Game {
    // MARK: Your game numbers
    // The engine never changes them during play: only your code does. They start at what Settings
    // set (0 if nothing), and game over puts them back there.

    /// Points. Show it yourself: `game.showText("⭐ " + String(game.score))`.
    public var score = 0
    /// Ouches, if your code counts them (`game.deaths += 1` in playerGotHurt).
    public var deaths = 0
    /// Lives, if your code uses them. Nothing happens by itself at 0: you call `game.lose()`.
    public var lives = 0
    /// The game's own frame counter, like every thing's timer. 60 frames is 1 second.
    /// It changes only when your code changes it (`game.timer += 1` in updateGame).
    public var timer = 0

    /// How many 🪙 are still in the level. Read only.
    public var coinsLeft: Int {
        Runtime.shared.world?.coins.filter { !$0.removed }.count ?? 0
    }
    /// How many enemies are still in the level. Read only.
    public var enemiesLeft: Int {
        Runtime.shared.world?.enemies.filter { !$0.removed }.count ?? 0
    }
    /// Which level you're on: 1, 2 or 3. Read only: `game.nextLevel()` changes it.
    public internal(set) var levelNumber = 1

    // MARK: Settings (top of the page, outside every function)

    /// Your map (page 10). Empty means this page's own level.
    public var level = ""
    /// More maps, drawn the same way. `game.nextLevel()` goes to the next one. "" means there isn't one.
    public var level2 = ""
    public var level3 = ""
    /// The sky fades from skyColor (at the top) to horizonColor (at the bottom):
    /// `.hex("1a1a40")`, `.rgb(255, 200, 150)`, `.black` or `.white`.
    public var skyColor: GameColor = Game.defaultSky
    /// The bottom of the sky. Until you set it, it is the same as skyColor.
    public var horizonColor: GameColor {
        get { horizonSetting ?? skyColor }
        set { horizonSetting = newValue }
    }
    /// A ready-made scene: sky colors, block color and scrolling layers. Set your own after it to change it.
    public var background: GameBackground {
        get { backgroundSetting }
        set {
            backgroundSetting = newValue
            let preset = newValue.preset
            skyColor = preset.sky
            horizonSetting = preset.horizon
            blockColor = preset.block
            presetLayers = preset.layers
        }
    }
    /// Emoji that fall from the top of the screen, like "❄️". "" stops it. Several emoji take turns.
    public var weather = ""
    /// The color of `#` blocks.
    public var blockColor: GameColor = Game.defaultBlock
    /// Draw `#` blocks as an emoji instead of a color, for example "🧱". "" means use blockColor.
    public var blockEmoji = ""
    /// Starting look for every coin.
    public var coinEmoji = "🪙"
    /// Starting look for every crab.
    public var crabEmoji = "🦀"
    /// Starting look for every bee.
    public var beeEmoji = "🐝"
    /// Starting look for every ghost.
    public var ghostEmoji = "👻"
    /// Starting look for every frog.
    public var frogEmoji = "🐸"
    /// Starting look for the spikes.
    public var spikeEmoji = "🌵"
    /// Starting look for the flag.
    public var flagEmoji = "🚩"
    /// Starting look for every spring.
    public var springEmoji = "🍄"
    /// Starting look for every star.
    public var starEmoji = "⭐"
    /// Starting look for every fireball.
    public var fireballEmoji = "🔥"
    /// The gray inspector line at the top right: x, y, speedX, speedY, isOnGround, plus the numbers
    /// this page is about. It's for you, the designer (like Unity's Inspector). false hides it.
    public var showNumbers = true

    static let defaultSky = GameColor.hex("bfe3ff")
    static let defaultBlock = GameColor.hex("6b4a2b")
    /// horizonColor's own value (nil: the same as skyColor).
    var horizonSetting: GameColor? = nil
    var backgroundSetting: GameBackground = .plain
    /// The layers of the background preset, and the page's own addLayer calls (the Backgrounds
    /// check counts only these).
    var presetLayers: [GameLayer] = []
    var layers: [GameLayer] = []
    static let maxLayers = 10

    init() {}

    // MARK: Calls

    /// Adds a row of emoji far behind the level. Each character is one spot `size` points wide; a
    /// space is a gap; the row repeats forever. y: how high its bottom sits (64 stands on the floor).
    /// distance: 1 scrolls with the level, 2 half as fast, 10 barely moves.
    public func addLayer(_ emoji: String, y: Int = 0, size: Int = 64, distance: Int = 2) {
        let layer = GameLayer(emoji: String(emoji.prefix(40)), y: max(-1000, min(2000, y)),
                              size: max(16, min(400, size)), distance: max(1, min(50, distance)))
        // The same call again (from a script that runs every frame) changes nothing.
        if layer.emoji.trimmingCharacters(in: .whitespaces).isEmpty || layers.contains(layer) { return }
        if layers.count >= Game.maxLayers { return }
        layers.append(layer)
    }
    /// Shows text at the top right for ONE frame. Each call adds one more line (at most 8).
    /// To keep it on the screen, call it every frame: from updateGame.
    public func showText(_ text: String) {
        Runtime.shared.showText(text)
    }
    /// Shows a big message in the middle for 2 seconds. A new message replaces the old one.
    public func showMessage(_ text: String) {
        Runtime.shared.showMessage(text)
    }
    /// Plays a sound effect once, right now: `game.playSound(.coin)`. A muted iPad plays nothing.
    public func playSound(_ sound: GameSound) {
        Runtime.shared.request(.sound(sound), source: nil)
    }
    /// Shakes the screen for a moment (20 frames). strength: 1 to 40.
    public func shake(strength: Int = 8) {
        Runtime.shared.request(.shake(max(1, min(40, strength))), source: nil)
    }
    /// Makes a new thing right now, with its middle at x, y. Its start script runs, then it gets
    /// these speeds (a speed of 0 keeps what its start script set). At most 50 made this way at
    /// once (the oldest goes first). They disappear after an ouch.
    public func spawn(_ kind: ThingKind, x: Int, y: Int, speedX: Int = 0, speedY: Int = 0) {
        Runtime.shared.world?.spawn(kind.kind, x: x, y: y, speedX: speedX, speedY: speedY)
    }
    /// "You win! 🎉". On lesson pages: "✅ Page complete!" only when every check is ✅.
    /// A message shown in the same frame goes under the banner.
    public func win() {
        Runtime.shared.requestWin()
    }
    /// "Game over" for 2 seconds, then the game starts over: game numbers back to their start
    /// values, level 1, and startGame runs.
    public func lose() {
        Runtime.shared.requestLose()
    }
    /// Goes to the next level that has a map (level2, then level3). The game numbers stay. After the
    /// last level, it wins.
    public func nextLevel() {
        Runtime.shared.requestNextLevel()
    }
}

/// The game. There is exactly one. Inside `updateGame(game:)`, `game` is this same game.
nonisolated(unsafe) public let game = Game()

/// The 12 sound effects: `game.playSound(.coin)`. The engine makes them itself (no sound files).
public enum GameSound: Int, CaseIterable, Sendable {
    case coin, jump, hurt, stomp, powerUp, win, lose, laser, explosion, boing, blip, whoosh
}

/// The kinds of thing `game.spawn` can make: `game.spawn(.fireball, x: player.x, y: player.y)`.
public enum ThingKind: Sendable {
    case coin, crab, bee, ghost, frog, fireball, spring, star
    var kind: Kind {
        switch self {
        case .coin: return .coin
        case .crab: return .crab
        case .bee: return .bee
        case .ghost: return .ghost
        case .frog: return .frog
        case .fireball: return .fireball
        case .spring: return .spring
        case .star: return .star
        }
    }
}

/// A row of background emoji (game.addLayer).
struct GameLayer: Equatable, Sendable {
    var emoji: String
    var y: Int
    var size: Int
    var distance: Int
}

/// Ready-made scenes: `game.background = .night`.
public enum GameBackground: Sendable, CaseIterable {
    case plain, day, sunset, night, forest, mountains, city, desert, snow, space, underwater, cave

    struct Preset {
        var sky: GameColor
        var horizon: GameColor?
        var block: GameColor
        var layers: [GameLayer]
    }

    var preset: Preset {
        func layer(_ e: String, y: Int, size: Int, distance: Int) -> GameLayer {
            GameLayer(emoji: e, y: y, size: size, distance: distance)
        }
        switch self {
        case .plain:
            return Preset(sky: Game.defaultSky, horizon: nil, block: Game.defaultBlock, layers: [])
        case .day:
            return Preset(sky: .hex("4aa8f0"), horizon: .hex("d2efff"), block: Game.defaultBlock, layers: [
                layer("    ☁️       ☁️          ☁️    ", y: 380, size: 90, distance: 12),
                layer("⛰️   🏔️     ⛰️  🏔️   ", y: 0, size: 240, distance: 6),
            ])
        case .sunset:
            return Preset(sky: .hex("3b2667"), horizon: .hex("ff9e6b"), block: .hex("5a3825"), layers: [
                layer("      🌞                              ", y: 280, size: 140, distance: 40),
                layer("⛰️     ⛰️          ⛰️    ", y: 0, size: 230, distance: 8),
                layer("🌴    🌴 🌴        🌴   ", y: 64, size: 130, distance: 3),
            ])
        case .night:
            return Preset(sky: .hex("0b1033"), horizon: .hex("2e3f7a"), block: .hex("4a3a2e"), layers: [
                layer("✨     ⭐      ✨    ✨        ⭐   ✨   ", y: 330, size: 28, distance: 30),
                layer("         🌕                    ", y: 400, size: 90, distance: 40),
                layer("🌲 🌲🌲     🌲   🌲🌲   ", y: 64, size: 120, distance: 4),
            ])
        case .forest:
            return Preset(sky: .hex("7cc4a4"), horizon: .hex("e1f5e4"), block: .hex("5b3d24"), layers: [
                layer("🌲🌲 🌲🌲🌲 🌲 🌲🌲 ", y: 30, size: 200, distance: 7),
                layer("🌳 🌲  🌳🌳  🌲 ", y: 64, size: 140, distance: 3),
            ])
        case .mountains:
            return Preset(sky: .hex("5f9fe0"), horizon: .hex("eaf4ff"), block: .hex("6a5848"), layers: [
                layer("🏔️    ⛰️   🏔️       ⛰️ ", y: 0, size: 300, distance: 10),
                layer("⛰️ ⛰️    ⛰️  ", y: 20, size: 170, distance: 4),
            ])
        case .city:
            return Preset(sky: .hex("ff8f6b"), horizon: .hex("ffe0a3"), block: .hex("55505a"), layers: [
                layer("🏢🏬 🏨🏢 🏬  🏢", y: 30, size: 190, distance: 8),
                layer("🏠 🏪🏡  🏫 🏠   ", y: 64, size: 110, distance: 3),
            ])
        case .desert:
            return Preset(sky: .hex("f0b25a"), horizon: .hex("fff0c8"), block: .hex("c48a42"), layers: [
                layer("     🌞                       ", y: 330, size: 110, distance: 40),
                layer("🏜️       🏜️      🏜️  ", y: 0, size: 230, distance: 8),
                layer("🌵     🌵  🌵       ", y: 64, size: 100, distance: 3),
            ])
        case .snow:
            return Preset(sky: .hex("9cc3e6"), horizon: .hex("f4f9ff"), block: .hex("7d8fa6"), layers: [
                layer("🏔️      🏔️    🏔️     ", y: 0, size: 280, distance: 9),
                layer("🌲 ⛄  🌲🌲    🌲 ", y: 64, size: 110, distance: 3),
            ])
        case .space:
            return Preset(sky: .hex("05030f"), horizon: .hex("1f1446"), block: .hex("5b5b6e"), layers: [
                layer("✨    ⭐     ✨  💫      ✨     ⭐  ", y: 140, size: 30, distance: 30),
                layer("      🪐                🌍           ", y: 330, size: 130, distance: 40),
                layer("      ☄️                    ", y: 420, size: 70, distance: 15),
            ])
        case .underwater:
            return Preset(sky: .hex("0b4f8c"), horizon: .hex("3cc0e0"), block: .hex("c8a46a"), layers: [
                layer("🐠        🐟           🐡      ", y: 300, size: 54, distance: 6),
                layer("🪸  🌿   🪸 🐚    🌿 ", y: 64, size: 90, distance: 3),
            ])
        case .cave:
            return Preset(sky: .hex("17110d"), horizon: .hex("3d2d22"), block: .hex("5c4a3a"), layers: [
                layer("💎        🕯️          💎     ", y: 260, size: 50, distance: 8),
                layer("🪨   🪨🪨     🪨  ", y: 64, size: 110, distance: 3),
            ])
        }
    }
}

/// A color, written the same way as the turtle colors.
public struct GameColor: Sendable, Equatable {
    let red: Int
    let green: Int
    let blue: Int

    public static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> GameColor {
        GameColor(red: max(0, min(255, red)), green: max(0, min(255, green)), blue: max(0, min(255, blue)))
    }
    /// `.hex("daf542")` or `.hex("#daf542")`.
    public static func hex(_ code: String) -> GameColor {
        var text = code.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = Int(text, radix: 16) else { return rgb(255, 0, 255) }
        return rgb((value >> 16) & 255, (value >> 8) & 255, value & 255)
    }
    public static let black = GameColor(red: 0, green: 0, blue: 0)
    public static let white = GameColor(red: 255, green: 255, blue: 255)
    public static let red = GameColor(red: 230, green: 57, blue: 70)
    public static let orange = GameColor(red: 244, green: 140, blue: 6)
    public static let yellow = GameColor(red: 255, green: 214, blue: 10)
    public static let green = GameColor(red: 56, green: 176, blue: 0)
    public static let blue = GameColor(red: 0, green: 119, blue: 182)
    public static let purple = GameColor(red: 123, green: 44, blue: 191)
    public static let pink = GameColor(red: 255, green: 133, blue: 161)
    public static let brown = GameColor(red: 107, green: 74, blue: 43)
    public static let gray = GameColor(red: 128, green: 128, blue: 128)

    /// Is it a dark color? (Light text goes on a dark sky.)
    var isDark: Bool { red * 299 + green * 587 + blue * 114 < 128_000 }
}

// MARK: - Friendly compile errors (students only ever see the message)
// Every game number is an Int. `player.x += 2.5` would otherwise give a confusing error about
// operand types, and `"⭐ " + game.score` one about overloads.

@available(*, unavailable, message: "Game numbers are whole numbers. Use 2 or 3, not 2.5.")
public func += (lhs: inout Int, rhs: Double) { fatalError() }

@available(*, unavailable, message: "Game numbers are whole numbers. Use 2 or 3, not 2.5.")
public func -= (lhs: inout Int, rhs: Double) { fatalError() }

@available(*, unavailable, message: "To join a number to text, turn the number into text first, like String(game.score) or String(game.deaths)")
public func + (lhs: String, rhs: Int) -> String { fatalError() }

@available(*, unavailable, message: "To join a number to text, turn the number into text first, like String(game.score) or String(game.deaths)")
public func + (lhs: Int, rhs: String) -> String { fatalError() }

@available(*, unavailable, message: "To join a number to text, turn the number into text first, like String(game.score) or String(game.deaths)")
public func += (lhs: inout String, rhs: Int) { fatalError() }

@available(*, unavailable, message: "Sounds belong to the game: write game.playSound(.coin)")
public func playSound(_ sound: GameSound) { fatalError() }

extension Game {
    @available(*, unavailable, message: "showText needs text. Turn the number into text first, like String(game.score) or String(game.deaths)")
    public func showText(_ number: Int) { fatalError() }

    @available(*, unavailable, message: "showMessage needs text. Turn the number into text first, like String(game.score) or String(game.deaths)")
    public func showMessage(_ number: Int) { fatalError() }

    @available(*, unavailable, message: "Pick a sound with a dot: game.playSound(.coin)")
    public func playSound(_ name: String) { fatalError() }
}
