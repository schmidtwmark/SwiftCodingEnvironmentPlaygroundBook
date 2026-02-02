//
//  RobotTypes.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 2/1/26.
//

import Foundation
import PlaygroundSupport

// MARK: - Grid Types

public struct GridSize: Hashable, Codable {
    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }
}

public struct Position: Hashable, Codable {
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

public enum Direction: Int, Codable, CaseIterable {
    case north = 0
    case east = 90
    case south = 180
    case west = 270

    public var rotationAngle: Double {
        Double(rawValue)
    }

    public func turnedRight() -> Direction {
        let newValue = (rawValue + 90) % 360
        return Direction(rawValue: newValue)!
    }

    public func turnedLeft() -> Direction {
        let newValue = (rawValue + 270) % 360
        return Direction(rawValue: newValue)!
    }
}

// MARK: - Wall

public struct Wall: Hashable, Codable {
    public let from: Position
    public let to: Position

    public init(from: Position, to: Position) {
        // Normalize so from is always "less than" to for consistent hashing
        if (from.row, from.column) < (to.row, to.column) {
            self.from = from
            self.to = to
        } else {
            self.from = to
            self.to = from
        }
    }

    /// Check if this wall blocks movement from a position in a direction
    public func blocks(from position: Position, direction: Direction) -> Bool {
        let nextPos = position.moved(in: direction)
        let wall = Wall(from: position, to: nextPos)
        return self == wall
    }
}

// MARK: - Level

public struct Level: Codable {
    public let gridSize: GridSize
    public let robotStart: Position
    public let robotDirection: Direction
    public let goalPosition: Position
    public let walls: [Wall]

    public init(gridSize: GridSize, robotStart: Position, robotDirection: Direction, goalPosition: Position, walls: [Wall]) {
        self.gridSize = gridSize
        self.robotStart = robotStart
        self.robotDirection = robotDirection
        self.goalPosition = goalPosition
        self.walls = walls
    }

    public var wallSet: Set<Wall> {
        Set(walls)
    }
}

// MARK: - Game State

public enum GameState: Equatable {
    case playing
    case won
    case lost(LossReason)
}

public enum LossReason: String, Codable, Equatable {
    case hitWall = "Hit a wall"
    case outOfBounds = "Went out of bounds"
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

// MARK: - PlaygroundValue Extensions

extension GridSize {
    public var playgroundValue: PlaygroundValue {
        .dictionary([
            "columns": .integer(columns),
            "rows": .integer(rows)
        ])
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .integer(columns)? = dict["columns"],
              case let .integer(rows)? = dict["rows"] else {
            return nil
        }
        self.init(columns: columns, rows: rows)
    }
}

extension Position {
    public var playgroundValue: PlaygroundValue {
        .dictionary([
            "column": .integer(column),
            "row": .integer(row)
        ])
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .integer(column)? = dict["column"],
              case let .integer(row)? = dict["row"] else {
            return nil
        }
        self.init(column: column, row: row)
    }
}

extension Direction {
    public var playgroundValue: PlaygroundValue {
        .integer(rawValue)
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .integer(value) = playgroundValue,
              let direction = Direction(rawValue: value) else {
            return nil
        }
        self = direction
    }
}

extension Wall {
    public var playgroundValue: PlaygroundValue {
        .dictionary([
            "from": from.playgroundValue,
            "to": to.playgroundValue
        ])
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              let fromValue = dict["from"],
              let toValue = dict["to"],
              let from = Position(fromValue),
              let to = Position(toValue) else {
            return nil
        }
        self.init(from: from, to: to)
    }
}

extension Level {
    public var playgroundValue: PlaygroundValue {
        .dictionary([
            "gridSize": gridSize.playgroundValue,
            "robotStart": robotStart.playgroundValue,
            "robotDirection": robotDirection.playgroundValue,
            "goalPosition": goalPosition.playgroundValue,
            "walls": .array(walls.map { $0.playgroundValue })
        ])
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              let gridSizeValue = dict["gridSize"],
              let gridSize = GridSize(gridSizeValue),
              let robotStartValue = dict["robotStart"],
              let robotStart = Position(robotStartValue),
              let robotDirectionValue = dict["robotDirection"],
              let robotDirection = Direction(robotDirectionValue),
              let goalPositionValue = dict["goalPosition"],
              let goalPosition = Position(goalPositionValue),
              case let .array(wallsArray)? = dict["walls"] else {
            return nil
        }

        let walls = wallsArray.compactMap { Wall($0) }
        self.init(gridSize: gridSize, robotStart: robotStart, robotDirection: robotDirection, goalPosition: goalPosition, walls: walls)
    }
}

extension LossReason {
    public var playgroundValue: PlaygroundValue {
        .string(rawValue)
    }

    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .string(value) = playgroundValue,
              let reason = LossReason(rawValue: value) else {
            return nil
        }
        self = reason
    }
}
