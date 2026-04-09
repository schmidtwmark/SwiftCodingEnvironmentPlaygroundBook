//
//  RobotTypes.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 2/1/26.
//

import Foundation
import PlaygroundSupport
import SwiftUI

// MARK: - Cell

public enum Cell: String, Codable, Sendable, Equatable {
    case wall = "#"
    case open = "."
}

// MARK: - Position

public struct Position: Hashable, Codable, Sendable {
    public let column: Int
    public let row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }

    func moved(in direction: Direction) -> Position {
        switch direction {
        case .north: return Position(column: column, row: row - 1)
        case .east: return Position(column: column + 1, row: row)
        case .south: return Position(column: column, row: row + 1)
        case .west: return Position(column: column - 1, row: row)
        }
    }
}

// MARK: - Direction

public enum Direction: Int, CaseIterable, Sendable {
    case north = 0
    case east = 90
    case south = 180
    case west = 270

    public var rotationAngle: Double { Double(rawValue) }

    public func turnedRight() -> Direction {
        Direction(rawValue: (rawValue + 90) % 360)!
    }

    public func turnedLeft() -> Direction {
        Direction(rawValue: (rawValue + 270) % 360)!
    }

    public func reversed() -> Direction {
        Direction(rawValue: (rawValue + 180) % 360)!
    }
}

extension Direction: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        switch str {
        case "north": self = .north
        case "east": self = .east
        case "south": self = .south
        case "west": self = .west
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid direction: \(str)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .north: try container.encode("north")
        case .east: try container.encode("east")
        case .south: try container.encode("south")
        case .west: try container.encode("west")
        }
    }
}

// MARK: - Key

public struct Key: Codable, Sendable, Equatable, Hashable {
    public let position: Position
    public let color: String

    public init(position: Position, color: String) {
        self.position = position
        self.color = color
    }
}

// MARK: - Door

public struct Door: Codable, Sendable, Equatable, Hashable {
    public let position: Position
    public let color: String

    public init(position: Position, color: String) {
        self.position = position
        self.color = color
    }
}

// MARK: - Enemy (bounces off walls)

public struct Enemy: Codable, Sendable, Equatable {
    public let startPosition: Position
    public let direction: Direction

    public init(startPosition: Position, direction: Direction) {
        self.startPosition = startPosition
        self.direction = direction
    }
}

// MARK: - Laser Orientation

public enum LaserOrientation: String, Codable, Sendable, Equatable {
    case horizontal
    case vertical
    case cross
}

// MARK: - Laser (timed beam, cycles on/off based on digit)

/// Laser timing per digit:
/// | Digit | ON | OFF | Period |
/// |-------|----|-----|--------|
/// | 1     | 2  | 3   | 5      |
/// | 2     | 3  | 2   | 5      |
/// | 3     | 2  | 2   | 4      |
/// | 4     | 3  | 3   | 6      |
/// | 5     | 4  | 2   | 6      |
/// | 6     | 4  | 3   | 7      |
public struct Laser: Codable, Sendable, Equatable, Hashable {
    public let position: Position
    public let color: String
    public let digit: Int
    public let orientation: LaserOrientation
    public let onTicks: Int
    public let offTicks: Int

    public init(position: Position, color: String, digit: Int, orientation: LaserOrientation = .cross,
                onTicks: Int, offTicks: Int) {
        self.position = position
        self.color = color
        self.digit = digit
        self.orientation = orientation
        self.onTicks = onTicks
        self.offTicks = offTicks
    }

    public func isActive(at tick: Int) -> Bool {
        let period = onTicks + offTicks
        guard period > 0 else { return true }
        return (tick % period) < onTicks
    }
}

private let laserTimings: [Int: (on: Int, off: Int)] = [
    1: (2, 3),
    2: (3, 2),
    3: (2, 2),
    4: (3, 3),
    5: (4, 2),
    6: (4, 3),
]

private let digitColorMap: [Character: (color: String, digit: Int)] = [
    "1": ("red", 1),
    "2": ("blue", 2),
    "3": ("green", 3),
    "4": ("yellow", 4),
    "5": ("purple", 5),
    "6": ("orange", 6),
]

// MARK: - Teleporter

public struct Teleporter: Codable, Sendable, Equatable {
    public let from: Position
    public let to: Position
    public let color: String

    public init(from: Position, to: Position, color: String = "purple") {
        self.from = from
        self.to = to
        self.color = color
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        from = try container.decode(Position.self, forKey: .from)
        to = try container.decode(Position.self, forKey: .to)
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "purple"
    }

    private enum CodingKeys: String, CodingKey { case from, to, color }

    public func destination(from position: Position) -> Position? {
        if position == self.from { return self.to }
        if position == self.to { return self.from }
        return nil
    }
}

// MARK: - Level

public struct Level: Sendable {
    public let cells: [[Cell]]
    public let robotStart: Position
    public let robotDirection: Direction
    public let goalPosition: Position
    public let keys: [Key]
    public let doors: [Door]
    public let enemies: [Enemy]
    public let lasers: [Laser]
    public let teleporters: [Teleporter]
    public var minimumMoves: Int?

    public var rows: Int { cells.count }
    public var columns: Int { cells.isEmpty ? 0 : cells[0].count }

    public init(
        cells: [[Cell]],
        robotStart: Position,
        robotDirection: Direction,
        goalPosition: Position,
        keys: [Key] = [],
        doors: [Door] = [],
        enemies: [Enemy] = [],
        lasers: [Laser] = [],
        teleporters: [Teleporter] = [],
        minimumMoves: Int? = nil
    ) {
        self.cells = cells
        self.robotStart = robotStart
        self.robotDirection = robotDirection
        self.goalPosition = goalPosition
        self.keys = keys
        self.doors = doors
        self.enemies = enemies
        self.lasers = lasers
        self.teleporters = teleporters
        self.minimumMoves = minimumMoves
    }

    public func isInBounds(_ position: Position) -> Bool {
        position.row >= 0 && position.row < rows &&
        position.column >= 0 && position.column < columns
    }

}

// MARK: - ASCII Level Parser

extension Level {
    /// Parse a level from a single ASCII string.
    ///
    /// **Symbols:**
    /// - `#` wall, `.` open
    /// - `^` `>` `v` `<` robot start + direction
    /// - `*` goal
    /// - `a`-`f` keys (a=red, b=blue, c=green, d=yellow, e=purple, f=orange)
    /// - `A`-`F` doors (matching key letter)
    /// - `U` `D` `L` `R` enemy (Up/Down/Left/Right, bounces off walls)
    /// - `1`-`6` laser beam (timed on/off per digit, disabled by matching key)
    /// - `(` `)` teleporter pair (purple)
    /// - `{` `}` teleporter pair (cyan)
    /// - `[` `]` teleporter pair (orange)
    public static func ascii(_ map: String) -> Level {
        let lines = map.split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
            .filter { !$0.isEmpty }

        var cells: [[Cell]] = []
        var robotStart: Position?
        var robotDirection: Direction = .north
        var goalPosition: Position?
        var keys: [Key] = []
        var doors: [Door] = []
        var enemies: [Enemy] = []
        var rawLasers: [(position: Position, color: String, digit: Int, onTicks: Int, offTicks: Int)] = []
        var bracketPositions: [String: [Position]] = [:]

        for (row, line) in lines.enumerated() {
            var cellRow: [Cell] = []
            for (col, char) in line.enumerated() {
                let pos = Position(column: col, row: row)
                switch char {
                case "#":
                    cellRow.append(.wall)
                case ".":
                    cellRow.append(.open)
                case "^":
                    cellRow.append(.open); robotStart = pos; robotDirection = .north
                case ">":
                    cellRow.append(.open); robotStart = pos; robotDirection = .east
                case "v":
                    cellRow.append(.open); robotStart = pos; robotDirection = .south
                case "<":
                    cellRow.append(.open); robotStart = pos; robotDirection = .west
                case "*":
                    cellRow.append(.open); goalPosition = pos
                case "a"..."f":
                    cellRow.append(.open); keys.append(Key(position: pos, color: letterColor(char)))
                case "A"..."F":
                    cellRow.append(.open); doors.append(Door(position: pos, color: letterColor(Character(char.lowercased()))))
                case "U":
                    cellRow.append(.open); enemies.append(Enemy(startPosition: pos, direction: .north))
                case "D":
                    cellRow.append(.open); enemies.append(Enemy(startPosition: pos, direction: .south))
                case "L":
                    cellRow.append(.open); enemies.append(Enemy(startPosition: pos, direction: .west))
                case "R":
                    cellRow.append(.open); enemies.append(Enemy(startPosition: pos, direction: .east))
                case "1"..."6":
                    cellRow.append(.open)
                    if let info = digitColorMap[char] {
                        let timing = laserTimings[info.digit] ?? (2, 2)
                        rawLasers.append((position: pos, color: info.color, digit: info.digit,
                                          onTicks: timing.on, offTicks: timing.off))
                    }
                case "(", ")":
                    cellRow.append(.open); bracketPositions["()", default: []].append(pos)
                case "{", "}":
                    cellRow.append(.open); bracketPositions["{}", default: []].append(pos)
                case "[", "]":
                    cellRow.append(.open); bracketPositions["[]", default: []].append(pos)
                default:
                    cellRow.append(.open)
                }
            }
            cells.append(cellRow)
        }

        // Compute laser orientations by checking adjacency with same-digit lasers
        let laserPositionsByDigit: [Int: Set<Position>] = {
            var dict: [Int: Set<Position>] = [:]
            for laser in rawLasers {
                dict[laser.digit, default: []].insert(laser.position)
            }
            return dict
        }()

        let lasers: [Laser] = rawLasers.map { raw in
            let sameDigitPositions = laserPositionsByDigit[raw.digit] ?? []
            let hasHorizontalNeighbor =
                sameDigitPositions.contains(Position(column: raw.position.column - 1, row: raw.position.row)) ||
                sameDigitPositions.contains(Position(column: raw.position.column + 1, row: raw.position.row))
            let hasVerticalNeighbor =
                sameDigitPositions.contains(Position(column: raw.position.column, row: raw.position.row - 1)) ||
                sameDigitPositions.contains(Position(column: raw.position.column, row: raw.position.row + 1))

            let orientation: LaserOrientation
            if hasHorizontalNeighbor && hasVerticalNeighbor {
                orientation = .cross
            } else if hasHorizontalNeighbor {
                orientation = .horizontal
            } else if hasVerticalNeighbor {
                orientation = .vertical
            } else {
                orientation = .cross
            }

            return Laser(position: raw.position, color: raw.color, digit: raw.digit,
                         orientation: orientation, onTicks: raw.onTicks, offTicks: raw.offTicks)
        }

        // Build teleporter pairs from brackets
        let bracketColors: [String: String] = ["()": "purple", "{}": "cyan", "[]": "orange"]
        var teleporters: [Teleporter] = []
        for (pair, positions) in bracketPositions {
            if positions.count >= 2 {
                teleporters.append(Teleporter(from: positions[0], to: positions[1], color: bracketColors[pair] ?? "purple"))
            }
        }

        guard let start = robotStart else { fatalError("No robot start (^>v<) found in map") }
        guard let goal = goalPosition else { fatalError("No goal (*) found in map") }

        return Level(
            cells: cells, robotStart: start, robotDirection: robotDirection, goalPosition: goal,
            keys: keys, doors: doors, enemies: enemies, lasers: lasers, teleporters: teleporters
        )
    }

    private static func letterColor(_ char: Character) -> String {
        switch char {
        case "a": return "red"
        case "b": return "blue"
        case "c": return "green"
        case "d": return "yellow"
        case "e": return "purple"
        case "f": return "orange"
        default: return "red"
        }
    }
}

// MARK: - Game State

public enum GameState: Equatable {
    case playing
    case won
    case lost(LossReason)
}

public enum LossReason: String, Codable, Equatable, Sendable {
    case hitWall = "Hit a wall"
    case outOfBounds = "Went out of bounds"
    case caughtByEnemy = "Caught by an enemy"
    case hitLaser = "Hit by a laser"
    case blockedByDoor = "Blocked by a locked door"
}

// MARK: - Robot State

public struct RobotState: Equatable {
    public var position: Position
    public var direction: Direction

    public init(position: Position, direction: Direction) {
        self.position = position
        self.direction = direction
    }
}

// MARK: - Enemy State (runtime)

public struct EnemyState: Equatable {
    public var position: Position
    public var direction: Direction

    public init(position: Position, direction: Direction) {
        self.position = position
        self.direction = direction
    }
}

// MARK: - Level State

public struct LevelState: Equatable {
    public var tick: Int = 0
    public var collectedKeys: Set<Int> = []
    public var openDoors: Set<Int> = []
    public var enemyStates: [EnemyState] = []

    public init() {}
}

// MARK: - Color Helpers

public func elementColor(_ name: String) -> Color {
    switch name {
    case "red": return .red
    case "blue": return .blue
    case "green": return .green
    case "yellow": return .yellow
    case "purple": return .purple
    case "orange": return .orange
    case "cyan": return .cyan
    case "pink": return .pink
    case "mint": return .mint
    default: return .orange
    }
}

// MARK: - PlaygroundValue Extensions

extension Position {
    public var playgroundValue: PlaygroundValue {
        .dictionary(["column": .integer(column), "row": .integer(row)])
    }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .integer(c)? = dict["column"],
              case let .integer(r)? = dict["row"] else { return nil }
        self.init(column: c, row: r)
    }
}

extension Direction {
    public var playgroundValue: PlaygroundValue { .integer(rawValue) }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .integer(v) = playgroundValue, let d = Direction(rawValue: v) else { return nil }
        self = d
    }
}

extension Key {
    public var playgroundValue: PlaygroundValue {
        .dictionary(["position": position.playgroundValue, "color": .string(color)])
    }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(d) = playgroundValue,
              let pv = d["position"], let p = Position(pv),
              case let .string(c)? = d["color"] else { return nil }
        self.init(position: p, color: c)
    }
}

extension Door {
    public var playgroundValue: PlaygroundValue {
        .dictionary(["position": position.playgroundValue, "color": .string(color)])
    }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(d) = playgroundValue,
              let pv = d["position"], let p = Position(pv),
              case let .string(c)? = d["color"] else { return nil }
        self.init(position: p, color: c)
    }
}

extension Enemy {
    public var playgroundValue: PlaygroundValue {
        .dictionary(["startPosition": startPosition.playgroundValue, "direction": direction.playgroundValue])
    }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(d) = playgroundValue,
              let pv = d["startPosition"], let p = Position(pv),
              let dv = d["direction"], let dir = Direction(dv) else { return nil }
        self.init(startPosition: p, direction: dir)
    }
}

extension Laser {
    public var playgroundValue: PlaygroundValue {
        .dictionary([
            "position": position.playgroundValue, "color": .string(color),
            "digit": .integer(digit), "orientation": .string(orientation.rawValue),
            "onTicks": .integer(onTicks), "offTicks": .integer(offTicks)
        ])
    }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(d) = playgroundValue,
              let pv = d["position"], let p = Position(pv),
              case let .string(c)? = d["color"],
              case let .integer(dig)? = d["digit"],
              case let .string(ori)? = d["orientation"],
              let orientation = LaserOrientation(rawValue: ori),
              case let .integer(on)? = d["onTicks"],
              case let .integer(off)? = d["offTicks"] else { return nil }
        self.init(position: p, color: c, digit: dig, orientation: orientation, onTicks: on, offTicks: off)
    }
}

extension Teleporter {
    public var playgroundValue: PlaygroundValue {
        .dictionary(["from": from.playgroundValue, "to": to.playgroundValue, "color": .string(color)])
    }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(d) = playgroundValue,
              let fv = d["from"], let f = Position(fv),
              let tv = d["to"], let t = Position(tv) else { return nil }
        let c: String
        if case let .string(s)? = d["color"] { c = s } else { c = "purple" }
        self.init(from: f, to: t, color: c)
    }
}

extension Level {
    public var playgroundValue: PlaygroundValue {
        var dict: [String: PlaygroundValue] = [
            "grid": .array(cells.map { row in .string(row.map { $0.rawValue }.joined()) }),
            "robotStart": robotStart.playgroundValue,
            "robotDirection": robotDirection.playgroundValue,
            "goalPosition": goalPosition.playgroundValue
        ]
        if !keys.isEmpty { dict["keys"] = .array(keys.map { $0.playgroundValue }) }
        if !doors.isEmpty { dict["doors"] = .array(doors.map { $0.playgroundValue }) }
        if !enemies.isEmpty { dict["enemies"] = .array(enemies.map { $0.playgroundValue }) }
        if !lasers.isEmpty { dict["lasers"] = .array(lasers.map { $0.playgroundValue }) }
        if !teleporters.isEmpty { dict["teleporters"] = .array(teleporters.map { $0.playgroundValue }) }
        if let par = minimumMoves { dict["minimumMoves"] = .integer(par) }
        return .dictionary(dict)
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .array(gridArray)? = dict["grid"],
              let rsv = dict["robotStart"], let rs = Position(rsv),
              let rdv = dict["robotDirection"], let rd = Direction(rdv),
              let gpv = dict["goalPosition"], let gp = Position(gpv) else { return nil }

        let cells: [[Cell]] = gridArray.compactMap { v in
            guard case let .string(row) = v else { return nil }
            return row.map { $0 == "#" ? Cell.wall : Cell.open }
        }

        func decodeArray<T>(_ key: String, _ decode: (PlaygroundValue) -> T?) -> [T] {
            guard case let .array(arr)? = dict[key] else { return [] }
            return arr.compactMap(decode)
        }

        let par: Int?
        if case let .integer(m)? = dict["minimumMoves"] { par = m } else { par = nil }

        self.init(
            cells: cells, robotStart: rs, robotDirection: rd, goalPosition: gp,
            keys: decodeArray("keys") { Key($0) },
            doors: decodeArray("doors") { Door($0) },
            enemies: decodeArray("enemies") { Enemy($0) },
            lasers: decodeArray("lasers") { Laser($0) },
            teleporters: decodeArray("teleporters") { Teleporter($0) },
            minimumMoves: par
        )
    }
}

extension LossReason {
    public var playgroundValue: PlaygroundValue { .string(rawValue) }
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .string(v) = playgroundValue, let r = LossReason(rawValue: v) else { return nil }
        self = r
    }
}

// MARK: - Preview Levels

public enum PreviewLevels {
    public static let simple = Level.ascii("""
#####
#^..#
#...#
#..*#
#####
""")

    public static let withWalls = Level.ascii("""
#######
#>....#
#.###.#
#.....#
#.###.#
#....*#
#######
""")

    public static let withKeys = Level.ascii("""
#####
#v.a#
#.#.#
#A#.#
#.#.#
#*#.#
#####
""")

    public static let withLasers = Level.ascii("""
#####
#v..#
#...#
#111#
#...#
#..*#
#####
""")

    public static let withEnemies = Level.ascii("""
#######
#v....#
##.####
#.R...#
##.####
#....*#
#######
""")
}
