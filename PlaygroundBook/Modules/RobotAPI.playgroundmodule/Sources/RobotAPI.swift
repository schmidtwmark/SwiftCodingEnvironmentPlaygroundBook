//
//  See LICENSE folder for this template's licensing information.
//
//  Abstract:
//  Contains classes/structs/enums/functions which are part of a module that is
//  automatically imported into user-editable code.
//

import BookCore

// Implement any classes/structs/enums/functions in the RobotAPI module which you
// want to be automatically imported and visible for users on playground pages
// and in user modules.
//
// This is controlled via the book-level `UserAutoImportedAuxiliaryModules`
// Manifest.plist key.

public let robotConsole = RobotLiveViewClient()

// MARK: - Predefined Levels

/// A simple 3x3 level with no walls - move from bottom-left to top-right
public let level1 = Level(
    gridSize: GridSize(columns: 3, rows: 3),
    robotStart: Position(column: 0, row: 2),
    robotDirection: .north,
    goalPosition: Position(column: 2, row: 0),
    walls: []
)

/// A 4x4 level with some walls to navigate around
public let level2 = Level(
    gridSize: GridSize(columns: 4, rows: 4),
    robotStart: Position(column: 0, row: 3),
    robotDirection: .east,
    goalPosition: Position(column: 3, row: 0),
    walls: [
        // Horizontal wall blocking direct path upward at row 2
        Wall(from: Position(column: 1, row: 2), to: Position(column: 1, row: 1)),
        Wall(from: Position(column: 2, row: 2), to: Position(column: 2, row: 1)),
        // Vertical wall on the right side
        Wall(from: Position(column: 2, row: 0), to: Position(column: 3, row: 0))
    ]
)

/// A maze-like 5x5 level
public let level3 = Level(
    gridSize: GridSize(columns: 5, rows: 5),
    robotStart: Position(column: 0, row: 4),
    robotDirection: .north,
    goalPosition: Position(column: 4, row: 0),
    walls: [
        // First row of walls
        Wall(from: Position(column: 1, row: 3), to: Position(column: 1, row: 2)),
        Wall(from: Position(column: 2, row: 3), to: Position(column: 2, row: 2)),
        // Second row of walls
        Wall(from: Position(column: 2, row: 1), to: Position(column: 2, row: 0)),
        Wall(from: Position(column: 3, row: 2), to: Position(column: 3, row: 1)),
        // Third row of walls
        Wall(from: Position(column: 3, row: 4), to: Position(column: 4, row: 4))
    ]
)
