//
//  Model.swift  (GameAPI: the things, the functions and their do-nothing built-in versions, the
//  buttons, the hidden wiring)
//
//  Platform independent: no UIKit, SpriteKit or PlaygroundSupport, so the Mac test harness
//  compiles exactly this file. Every number a student touches is a whole number (Int). 60 frames
//  is 1 second. x grows to the right, y grows UP. One map square is 64 points.
//
//  One movement rule for every thing: every frame, after it calls the functions, the engine moves each
//  thing by its speedX and speedY. Blocks stop things (ghosts float through them). Landing on a
//  block or bumping your head sets speedY to 0. Bumping a wall sideways stops the thing but keeps
//  its speedX, so a function can flip it. Nothing falls unless its own update function adds gravity.
//

import Foundation

/// One map square is 64 points.
public let tileSize = 64

// MARK: - Functions: you write them, the engine calls them
// These are the built-in versions, and every one of them does nothing. A function on the page with
// EXACTLY the same first line replaces the built-in one (normal Swift name lookup: the page's
// function wins). A function whose first line is different (a misspelled name or label, an extra
// parameter, another type) is just another function: the engine keeps using the built-in one, which
// does nothing, and the header above the game says which first line it expected ("Can't find:").
//
// Everything the game does comes from code on the page: even winning at the 🚩, getting hurt by an
// enemy, and "Ouch!". Only the engine's rules are built in: moving every thing by its speeds, blocks,
// the camera, an ouch for 🌵 spikes or for falling out of the level, the blink after an ouch, and
// drawing.

/// The player's start function. Runs once when the level starts, and again after every ouch.
public func startPlayer(player: Player) { builtIn(.startPlayer) }

/// The player's update function. Runs 60 times a second.
public func updatePlayer(player: Player) { builtIn(.updatePlayer) }

/// The game's start function. Runs once when the game starts, and again when the game starts over
/// (after game over, or play again after a win). It runs before every other function, and NOT after an ouch.
public func startGame(game: Game) { builtIn(.startGame) }

/// The game's update function. Runs 60 times a second, after every other function (events too), so it sees
/// the frame's final numbers. Draw your text here.
public func updateGame(game: Game) { builtIn(.updateGame) }

/// Runs once for EACH 🦀 when the level starts, and again after every ouch. `crab` is that crab.
public func startCrab(crab: Crab) { builtIn(.startCrab) }

/// Runs 60 times a second for EACH 🦀. `crab` is the crab whose turn it is.
public func updateCrab(crab: Crab) { builtIn(.updateCrab) }

/// Runs once for EACH 🐝 when the level starts, and again after every ouch. `bee` is that bee.
public func startBee(bee: Bee) { builtIn(.startBee) }

/// Runs 60 times a second for EACH 🐝. `bee` is the bee whose turn it is.
public func updateBee(bee: Bee) { builtIn(.updateBee) }

/// Runs once for EACH 👻 when the level starts, and again after every ouch. `ghost` is that ghost.
public func startGhost(ghost: Ghost) { builtIn(.startGhost) }

/// Runs 60 times a second for EACH 👻. `ghost` is the ghost whose turn it is. Ghosts float through blocks.
public func updateGhost(ghost: Ghost) { builtIn(.updateGhost) }

/// Runs once for EACH 🐸 when the level starts, and again after every ouch. `frog` is that frog.
public func startFrog(frog: Frog) { builtIn(.startFrog) }

/// Runs 60 times a second for EACH 🐸. `frog` is the frog whose turn it is.
public func updateFrog(frog: Frog) { builtIn(.updateFrog) }

/// Runs once for EACH 🔥, right when it is made. `fireball` is that fireball.
public func startFireball(fireball: Fireball) { builtIn(.startFireball) }

/// Runs 60 times a second for EACH 🔥. `fireball` is the fireball whose turn it is.
public func updateFireball(fireball: Fireball) { builtIn(.updateFireball) }

// MARK: - Event functions: the engine calls them when something happens
// The touch functions run EVERY frame two things touch, and get the touched thing.

/// Every frame you touch a 🪙. `coin` is that coin.
public func playerTouchedCoin(coin: Coin) { builtIn(.playerTouchedCoin) }

/// Every frame you touch an enemy. `enemy` is that enemy. (An enemy hurts you only if this says
/// `player.hurt()`.)
public func playerTouchedEnemy(enemy: Enemy) { builtIn(.playerTouchedEnemy) }

/// Every frame you touch the 🚩. (The 🚩 wins only if this says `game.win()`.)
public func playerTouchedFlag() { builtIn(.playerTouchedFlag) }

/// Every frame you touch a 🍄. `spring` is that spring.
public func playerTouchedSpring(spring: Spring) { builtIn(.playerTouchedSpring) }

/// Every frame you touch a ⭐. `star` is that star.
public func playerTouchedStar(star: Star) { builtIn(.playerTouchedStar) }

/// Every frame a 🔥 touches an enemy. `fireball` is that fireball; `enemy` is that enemy.
public func fireballTouchedEnemy(fireball: Fireball, enemy: Enemy) { builtIn(.fireballTouchedEnemy) }

/// Runs ONCE for every ouch (an enemy, spikes, a fall, or `player.hurt()`), at the end of that frame.
/// A `player.hurt()` inside it does nothing.
public func playerGotHurt() { builtIn(.playerGotHurt) }

/// Every built-in function calls this: it records that the engine had to use the built-in (the page's
/// function is missing, or its first line is different), so the checks and the header can say so.
func builtIn(_ function: FunctionName) {
    Runtime.shared.ranBuiltIn(function)
}

/// The 21 functions a page hands to the engine, by the exact first line the engine looks for.
enum FunctionName: Int, CaseIterable, Sendable {
    case startPlayer, updatePlayer, startGame, updateGame
    case startCrab, updateCrab, startBee, updateBee, startGhost, updateGhost, startFrog, updateFrog
    case startFireball, updateFireball
    case playerTouchedCoin, playerTouchedEnemy, playerTouchedFlag, playerTouchedSpring, playerTouchedStar
    case fireballTouchedEnemy, playerGotHurt

    var bit: Int { 1 << rawValue }

    var name: String { String(describing: self) }

    /// What goes between the parentheses of the first line.
    var parameters: String {
        switch self {
        case .startPlayer, .updatePlayer: return "player: Player"
        case .startGame, .updateGame: return "game: Game"
        case .startCrab, .updateCrab: return "crab: Crab"
        case .startBee, .updateBee: return "bee: Bee"
        case .startGhost, .updateGhost: return "ghost: Ghost"
        case .startFrog, .updateFrog: return "frog: Frog"
        case .startFireball, .updateFireball: return "fireball: Fireball"
        case .playerTouchedCoin: return "coin: Coin"
        case .playerTouchedEnemy: return "enemy: Enemy"
        case .playerTouchedFlag, .playerGotHurt: return ""
        case .playerTouchedSpring: return "spring: Spring"
        case .playerTouchedStar: return "star: Star"
        case .fireballTouchedEnemy: return "fireball: Fireball, enemy: Enemy"
        }
    }

    /// The first line a page must have so the engine uses its version.
    var firstLine: String { "func \(name)(\(parameters)) {" }
}

// MARK: - Things

enum Kind: Sendable {
    case player, crab, bee, ghost, frog, coin, flag, spring, star, fireball

    var isEnemy: Bool {
        switch self {
        case .crab, .bee, .ghost, .frog: return true
        default: return false
        }
    }
    /// Coins, springs and stars: they have no start or update functions, only touch events.
    var isPickup: Bool { self == .coin || self == .spring || self == .star }
    /// Blocks stop it (everything except ghosts).
    var usesBlocks: Bool { self != .ghost }
    /// Walkers start standing on the floor of their square; everything else starts in the middle.
    var startsOnFloor: Bool { self == .player || self == .crab || self == .frog || self == .spring }
    var name: String { String(describing: self) }
}

/// Anything in the game. Every thing follows the one movement rule: every frame, after the
/// functions run, the engine moves it by `speedX` and `speedY`.
public class Thing {
    /// Where its middle is. Bigger x is further right. Read it to compare places; to move, change speedX.
    public var x: Int
    /// Where its middle is. Bigger y is higher. Read it to compare places; to move, change speedY.
    public var y: Int
    /// How far the engine moves it sideways every frame. Positive is right, negative is left.
    /// Bumping into a wall stops it but doesn't change speedX.
    public var speedX: Int = 0
    /// How far the engine moves it up every frame. Negative is down.
    /// Landing on a block, or bumping into one from below, sets it back to 0.
    public var speedY: Int = 0
    /// What it looks like. Change it any time: `player.emoji = "🦊"`. The engine mirrors it to face
    /// the way speedX points.
    public var emoji: String
    /// Its own frame counter. Starts at 0 and changes only when your code changes it (count with
    /// `timer += 1`, start over with `timer = 0`). Goes back to 0 after an ouch. 60 frames is 1 second.
    public var timer: Int = 0

    let kind: Kind
    /// The way it faced the last time its speedX wasn't 0.
    var lastFacedRight: Bool
    var removed = false
    /// Made by game.spawn while the game runs (not by the map).
    var spawned = false
    /// Standing on a block, as of the last physics step.
    var grounded = false
    /// Position before this frame's functions ran.
    var x0 = 0, y0 = 0
    /// Where the map put this thing.
    var startX = 0, startY = 0
    /// Its start function runs at the beginning of the next frame.
    var needsStart = false
    weak var world: World?

    init(kind: Kind, emoji: String) {
        self.kind = kind
        self.emoji = emoji
        self.x = 0
        self.y = 0
        self.lastFacedRight = (kind == .player)
    }

    /// The way it faces: the sign of speedX, or the last way it moved while speedX is 0.
    /// Enemies start facing left and the player starts facing right.
    var facesRight: Bool {
        if speedX > 0 { return true }
        if speedX < 0 { return false }
        return lastFacedRight
    }

    /// true while standing on a block.
    /// (Measured where the engine last put the thing, so a function that pushes the player into a
    /// wall can't make "standing" true in mid-air and climb the wall.)
    public func isOnGround() -> Bool {
        guard world != nil, !removed, kind.usesBlocks else { return false }
        return grounded
    }

    /// true when a block or the edge of the level is right in front.
    /// "In front" is the way speedX points (when speedX is 0, the way it last moved).
    public func facingWall() -> Bool {
        guard let world, !removed else { return false }
        return world.blocked(self, x: x + (facesRight ? 1 : -1), y: y)
    }

    /// true when it faces right: the way speedX points, or the way it last moved.
    public func facingRight() -> Bool {
        facesRight
    }

    /// true when standing on a block and the next step the way it faces would walk off the edge.
    public func facingLedge() -> Bool {
        guard let world, isOnGround() else { return false }
        let probeX = facesRight ? x + World.half : x - World.half - 1
        return !world.solidPoint(x: probeX, y: y - World.half - 1)
    }

    /// Takes it out of the game. On the player it does the same as `player.hurt()`.
    public func remove() {
        if let hero = self as? Player {
            hero.hurt()
        } else {
            world?.remove(self)
        }
    }
}

/// The hero. There is exactly one: `player` (it works in every function).
public final class Player: Thing {
    init() { super.init(kind: .player, emoji: "🙂") }

    /// Ouch! The player and every enemy go back to their starts (speeds and timers back to 0),
    /// spawned things disappear, start functions run again next frame, `playerGotHurt()` runs once, and
    /// the player blinks for 1 second (enemies and spikes can't hurt it while it blinks).
    public func hurt() {
        world?.hurt()
    }
}

/// A crab, a bee, a ghost or a frog. Touching one runs `playerTouchedEnemy(enemy:)`.
public class Enemy: Thing {}

/// A 🦀. Blocks stop it.
public final class Crab: Enemy {
    init() { super.init(kind: .crab, emoji: "🦀") }
}

/// A 🐝. Blocks stop it.
public final class Bee: Enemy {
    init() { super.init(kind: .bee, emoji: "🐝") }
}

/// A 👻. It floats right through blocks.
public final class Ghost: Enemy {
    init() { super.init(kind: .ghost, emoji: "👻") }
}

/// A 🐸. Blocks stop it.
public final class Frog: Enemy {
    init() { super.init(kind: .frog, emoji: "🐸") }
}

/// A 🪙. Touching one runs `playerTouchedCoin(coin:)`.
public final class Coin: Thing {
    init() { super.init(kind: .coin, emoji: "🪙") }
}

/// A 🍄. It stands on the floor, and you walk right through it. Touching one runs
/// `playerTouchedSpring(spring:)`.
public final class Spring: Thing {
    init() { super.init(kind: .spring, emoji: "🍄") }
}

/// A ⭐. It floats in the middle of its square. Touching one runs `playerTouchedStar(star:)`.
public final class Star: Thing {
    init() { super.init(kind: .star, emoji: "⭐") }
}

/// A 🔥, made only by `game.spawn(.fireball, ...)`. Blocks stop it, and it never hurts you.
/// Touching an enemy runs `fireballTouchedEnemy(fireball:enemy:)`.
public final class Fireball: Thing {
    init() { super.init(kind: .fireball, emoji: "🔥") }
}

/// The 🚩 (not part of the student API).
final class Flag: Thing {
    init() { super.init(kind: .flag, emoji: "🚩") }
}

/// The hero. There is exactly one. Inside `updatePlayer(player:)`, `player` is this same hero.
nonisolated(unsafe) public let player = Player()

// MARK: - Buttons

/// The game buttons: ◀ ▶ ▲ ▼ on the screen, or the ← → ↑ ↓ arrow keys. The ▼ button appears
/// once your code asks about `.down`.
public enum GameKey: Sendable {
    case left, right, up, down
    var bit: Int {
        switch self {
        case .left: return 1
        case .right: return 2
        case .up: return 4
        case .down: return 8
        }
    }
}

/// true every frame the button is held down.
public func isPressed(_ key: GameKey) -> Bool {
    let runtime = Runtime.shared
    if key == .down { runtime.usesDown = true }
    return runtime.input.now & key.bit != 0
}

/// true only on the first frame of a press.
public func justPressed(_ key: GameKey) -> Bool {
    let runtime = Runtime.shared
    if key == .down { runtime.usesDown = true }
    return runtime.input.now & key.bit != 0 && runtime.input.before & key.bit == 0
}

// MARK: - The functions a page hands to the engine

/// The 21 functions a page hands to the engine.
struct Functions {
    var startPlayer: (Player) -> Void
    var updatePlayer: (Player) -> Void
    var startGame: (Game) -> Void
    var updateGame: (Game) -> Void
    var startCrab: (Crab) -> Void
    var updateCrab: (Crab) -> Void
    var startBee: (Bee) -> Void
    var updateBee: (Bee) -> Void
    var startGhost: (Ghost) -> Void
    var updateGhost: (Ghost) -> Void
    var startFrog: (Frog) -> Void
    var updateFrog: (Frog) -> Void
    var startFireball: (Fireball) -> Void
    var updateFireball: (Fireball) -> Void
    var playerTouchedCoin: (Coin) -> Void
    var playerTouchedEnemy: (Enemy) -> Void
    var playerTouchedFlag: () -> Void
    var playerTouchedSpring: (Spring) -> Void
    var playerTouchedStar: (Star) -> Void
    var fireballTouchedEnemy: (Fireball, Enemy) -> Void
    var playerGotHurt: () -> Void

    /// Functions that do nothing at all (posters, engine rule tests and other tools).
    static var none: Functions {
        Functions(startPlayer: { _ in }, updatePlayer: { _ in }, startGame: { _ in }, updateGame: { _ in },
                startCrab: { _ in }, updateCrab: { _ in }, startBee: { _ in }, updateBee: { _ in },
                startGhost: { _ in }, updateGhost: { _ in }, startFrog: { _ in }, updateFrog: { _ in },
                startFireball: { _ in }, updateFireball: { _ in },
                playerTouchedCoin: { _ in }, playerTouchedEnemy: { _ in }, playerTouchedFlag: {},
                playerTouchedSpring: { _ in }, playerTouchedStar: { _ in },
                fireballTouchedEnemy: { _, _ in }, playerGotHurt: {})
    }

    /// The enemy's start function.
    func start(_ e: Enemy) {
        switch e {
        case let crab as Crab: startCrab(crab)
        case let bee as Bee: startBee(bee)
        case let ghost as Ghost: startGhost(ghost)
        case let frog as Frog: startFrog(frog)
        default: break
        }
    }

    /// The enemy's update function.
    func update(_ e: Enemy) {
        switch e {
        case let crab as Crab: updateCrab(crab)
        case let bee as Bee: updateBee(bee)
        case let ghost as Ghost: updateGhost(ghost)
        case let frog as Frog: updateFrog(frog)
        default: break
        }
    }
}

/// Every function's built-in version (what a page gets for a function it doesn't hand over).
func builtInFunctions() -> Functions {
    Functions(startPlayer: startPlayer(player:), updatePlayer: updatePlayer(player:),
            startGame: startGame(game:), updateGame: updateGame(game:),
            startCrab: startCrab(crab:), updateCrab: updateCrab(crab:),
            startBee: startBee(bee:), updateBee: updateBee(bee:),
            startGhost: startGhost(ghost:), updateGhost: updateGhost(ghost:),
            startFrog: startFrog(frog:), updateFrog: updateFrog(frog:),
            startFireball: startFireball(fireball:), updateFireball: updateFireball(fireball:),
            playerTouchedCoin: playerTouchedCoin(coin:), playerTouchedEnemy: playerTouchedEnemy(enemy:),
            playerTouchedFlag: playerTouchedFlag,
            playerTouchedSpring: playerTouchedSpring(spring:), playerTouchedStar: playerTouchedStar(star:),
            fireballTouchedEnemy: fireballTouchedEnemy(fireball:enemy:), playerGotHurt: playerGotHurt)
}

// MARK: - The hidden wiring (hidden code only)

/// Hands a page's functions to the engine. Every page's hidden code is the same, apart from the page:
///
///     func _startGamePage() {
///         let wire = GameWiring(.walk)
///         wire.player(start: startPlayer(player:), update: updatePlayer(player:))
///         ...
///         wire.start()
///     }
///     _startGamePage()
///
/// Each function is named by its full name, so the page's own function is used when its first line is
/// exactly the engine's, and the built-in one otherwise (a different first line is just another
/// function, never an error). The calls sit inside a function so that a function written twice gives
/// "invalid redeclaration" on the student's own line only, never "ambiguous use" in the hidden code.
public final class GameWiring {
    let page: GamePage
    var functions = builtInFunctions()
    /// Prints frame timing to the console (spike tests only).
    public var diagnostics = false

    public init(_ page: GamePage) { self.page = page }

    public func player(start: @escaping (Player) -> Void, update: @escaping (Player) -> Void) {
        functions.startPlayer = start
        functions.updatePlayer = update
    }
    public func game(start: @escaping (Game) -> Void, update: @escaping (Game) -> Void) {
        functions.startGame = start
        functions.updateGame = update
    }
    public func crab(start: @escaping (Crab) -> Void, update: @escaping (Crab) -> Void) {
        functions.startCrab = start
        functions.updateCrab = update
    }
    public func bee(start: @escaping (Bee) -> Void, update: @escaping (Bee) -> Void) {
        functions.startBee = start
        functions.updateBee = update
    }
    public func ghost(start: @escaping (Ghost) -> Void, update: @escaping (Ghost) -> Void) {
        functions.startGhost = start
        functions.updateGhost = update
    }
    public func frog(start: @escaping (Frog) -> Void, update: @escaping (Frog) -> Void) {
        functions.startFrog = start
        functions.updateFrog = update
    }
    public func fireball(start: @escaping (Fireball) -> Void, update: @escaping (Fireball) -> Void) {
        functions.startFireball = start
        functions.updateFireball = update
    }
    public func touches(coin: @escaping (Coin) -> Void, enemy: @escaping (Enemy) -> Void, flag: @escaping () -> Void,
                        spring: @escaping (Spring) -> Void, star: @escaping (Star) -> Void) {
        functions.playerTouchedCoin = coin
        functions.playerTouchedEnemy = enemy
        functions.playerTouchedFlag = flag
        functions.playerTouchedSpring = spring
        functions.playerTouchedStar = star
    }
    public func events(playerGotHurt: @escaping () -> Void, fireballTouchedEnemy: @escaping (Fireball, Enemy) -> Void) {
        functions.playerGotHurt = playerGotHurt
        functions.fireballTouchedEnemy = fireballTouchedEnemy
    }

    /// Hands everything to the platform: the iPad shows the live view (Engine.swift); the Mac test
    /// harness keeps it for runHarness() (Tests/Headless.swift). The level is read on the next turn
    /// of the main run loop, after the rest of the page's top-level code (game.level, Settings) has run.
    public func start() {
        GameLauncher.launch(StartBox(page: page, functions: functions, diagnostics: diagnostics))
    }
}

/// Carries the page's functions to the main thread, where they always run.
final class StartBox: @unchecked Sendable {
    let page: GamePage
    let functions: Functions
    let diagnostics: Bool
    /// Step Through My Code: draw the level, never call the functions (set by the iPad launcher).
    var stepMode = false
    init(page: GamePage, functions: Functions, diagnostics: Bool) {
        self.page = page
        self.functions = functions
        self.diagnostics = diagnostics
    }
}
