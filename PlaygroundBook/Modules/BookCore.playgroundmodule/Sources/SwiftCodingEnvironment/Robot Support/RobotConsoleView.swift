//
//  RobotConsoleView.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 2/1/26.
//

import SwiftUI

// MARK: - RobotConsoleView

public struct RobotConsoleView: ConsoleView {

    @ObservedObject public var console: RobotConsole
    @Environment(\.colorScheme) var colorScheme

    public init(console: RobotConsole) {
        self.console = console
    }

    public var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if let level = console.level, let robotState = console.robotState {
                GridView(level: level, robotState: robotState, gameState: console.gameState)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Waiting for level...")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            // Game state overlay
            if case .won = console.gameState {
                WinOverlay()
            } else if case .lost(let reason) = console.gameState {
                LoseOverlay(reason: reason)
            }
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(uiColor: .systemBackground) : Color(uiColor: .secondarySystemBackground)
    }
}

// MARK: - GridView

struct GridView: View {
    let level: Level
    let robotState: RobotState
    let gameState: GameState

    private let cellSize: CGFloat = 60
    private let wallThickness: CGFloat = 4

    var body: some View {
        let gridWidth = CGFloat(level.gridSize.columns) * cellSize
        let gridHeight = CGFloat(level.gridSize.rows) * cellSize

        ZStack(alignment: .topLeading) {
            // Grid cells
            VStack(spacing: 0) {
                ForEach(0..<level.gridSize.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<level.gridSize.columns, id: \.self) { column in
                            CellView(
                                position: Position(column: column, row: row),
                                isGoal: Position(column: column, row: row) == level.goalPosition,
                                cellSize: cellSize
                            )
                        }
                    }
                }
            }

            // Walls
            ForEach(Array(level.walls.enumerated()), id: \.offset) { _, wall in
                WallView(wall: wall, cellSize: cellSize, thickness: wallThickness, gridSize: level.gridSize)
            }

            // Border walls (outer edges)
            Rectangle()
                .stroke(Color.primary, lineWidth: wallThickness)
                .frame(width: gridWidth, height: gridHeight)

            // Robot
            RobotView(
                position: robotState.position,
                direction: robotState.direction,
                cellSize: cellSize,
                isLost: gameState != .playing && gameState != .won
            )
        }
        .frame(width: gridWidth, height: gridHeight)
    }
}

// MARK: - CellView

struct CellView: View {
    let position: Position
    let isGoal: Bool
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isGoal ? Color.green.opacity(0.3) : Color.clear)
                .frame(width: cellSize, height: cellSize)

            Rectangle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: cellSize, height: cellSize)

            if isGoal {
                Image(systemName: "flag.fill")
                    .font(.system(size: cellSize * 0.4))
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - WallView

struct WallView: View {
    let wall: Wall
    let cellSize: CGFloat
    let thickness: CGFloat
    let gridSize: GridSize

    var body: some View {
        // Calculate wall position based on the edge between two cells
        let (x, y, width, height) = wallGeometry

        Rectangle()
            .fill(Color.primary)
            .frame(width: width, height: height)
            .position(x: x, y: y)
    }

    private var wallGeometry: (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let from = wall.from
        let to = wall.to

        // Determine if wall is horizontal or vertical
        if from.row == to.row {
            // Vertical wall (between columns)
            let col = max(from.column, to.column)
            let x = CGFloat(col) * cellSize
            let y = CGFloat(from.row) * cellSize + cellSize / 2
            return (x, y, thickness, cellSize)
        } else {
            // Horizontal wall (between rows)
            let row = max(from.row, to.row)
            let x = CGFloat(from.column) * cellSize + cellSize / 2
            let y = CGFloat(row) * cellSize
            return (x, y, cellSize, thickness)
        }
    }
}

// MARK: - RobotView

struct RobotView: View {
    let position: Position
    let direction: Direction
    let cellSize: CGFloat
    let isLost: Bool

    var body: some View {
        // Position robot at center of its cell
        let xPos = CGFloat(position.column) * cellSize + cellSize / 2
        let yPos = CGFloat(position.row) * cellSize + cellSize / 2

        Image(systemName: "arrowtriangle.up.fill")
            .font(.system(size: cellSize * 0.5))
            .foregroundColor(isLost ? .red : .blue)
            .rotationEffect(.degrees(direction.rotationAngle))
            .position(x: xPos, y: yPos)
            .animation(.easeInOut(duration: 0.3), value: position.column)
            .animation(.easeInOut(duration: 0.3), value: position.row)
            .animation(.easeInOut(duration: 0.3), value: direction)
    }
}

// MARK: - WinOverlay

struct WinOverlay: View {
    var body: some View {
        ZStack {
            Color.green.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)

                Text("You Win!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.8))
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - LoseOverlay

struct LoseOverlay: View {
    let reason: LossReason

    var body: some View {
        ZStack {
            Color.red.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("Game Over")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(reason.rawValue)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.8))
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Preview Levels

enum PreviewLevels {
    /// Simple 3x3 level with no walls
    static let simple = Level(
        gridSize: GridSize(columns: 3, rows: 3),
        robotStart: Position(column: 0, row: 2),
        robotDirection: .north,
        goalPosition: Position(column: 2, row: 0),
        walls: []
    )

    /// 4x4 level with walls
    static let withWalls = Level(
        gridSize: GridSize(columns: 4, rows: 4),
        robotStart: Position(column: 0, row: 3),
        robotDirection: .east,
        goalPosition: Position(column: 3, row: 0),
        walls: [
            Wall(from: Position(column: 1, row: 2), to: Position(column: 1, row: 1)),
            Wall(from: Position(column: 2, row: 2), to: Position(column: 2, row: 1)),
            Wall(from: Position(column: 2, row: 0), to: Position(column: 3, row: 0))
        ]
    )

    /// 5x5 maze level
    static let maze = Level(
        gridSize: GridSize(columns: 5, rows: 5),
        robotStart: Position(column: 0, row: 4),
        robotDirection: .north,
        goalPosition: Position(column: 4, row: 0),
        walls: [
            Wall(from: Position(column: 1, row: 3), to: Position(column: 1, row: 2)),
            Wall(from: Position(column: 2, row: 3), to: Position(column: 2, row: 2)),
            Wall(from: Position(column: 2, row: 1), to: Position(column: 2, row: 0)),
            Wall(from: Position(column: 3, row: 2), to: Position(column: 3, row: 1)),
            Wall(from: Position(column: 3, row: 4), to: Position(column: 4, row: 4))
        ]
    )
}

// MARK: - Previews

#Preview("Grid - Simple 3x3") {
    GridView(
        level: PreviewLevels.simple,
        robotState: RobotState(
            position: Position(column: 0, row: 2),
            direction: .north
        ),
        gameState: .playing
    )
    .padding()
}

#Preview("Grid - With Walls 4x4") {
    GridView(
        level: PreviewLevels.withWalls,
        robotState: RobotState(
            position: Position(column: 0, row: 3),
            direction: .east
        ),
        gameState: .playing
    )
    .padding()
}

#Preview("Grid - Maze 5x5") {
    GridView(
        level: PreviewLevels.maze,
        robotState: RobotState(
            position: Position(column: 0, row: 4),
            direction: .north
        ),
        gameState: .playing
    )
    .padding()
}

#Preview("Grid - Robot Moved") {
    GridView(
        level: PreviewLevels.simple,
        robotState: RobotState(
            position: Position(column: 1, row: 1),
            direction: .east
        ),
        gameState: .playing
    )
    .padding()
}

#Preview("Grid - Won State") {
    GridView(
        level: PreviewLevels.simple,
        robotState: RobotState(
            position: Position(column: 2, row: 0),
            direction: .north
        ),
        gameState: .won
    )
    .padding()
}

#Preview("Grid - Lost State (Hit Wall)") {
    GridView(
        level: PreviewLevels.withWalls,
        robotState: RobotState(
            position: Position(column: 1, row: 2),
            direction: .north
        ),
        gameState: .lost(.hitWall)
    )
    .padding()
}

#Preview("Win Overlay") {
    ZStack {
        Color.gray
        WinOverlay()
    }
}

#Preview("Lose Overlay - Hit Wall") {
    ZStack {
        Color.gray
        LoseOverlay(reason: .hitWall)
    }
}

#Preview("Lose Overlay - Out of Bounds") {
    ZStack {
        Color.gray
        LoseOverlay(reason: .outOfBounds)
    }
}

#Preview("Waiting State") {
    ZStack {
        Color(uiColor: .secondarySystemBackground)
            .ignoresSafeArea()
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Waiting for level...")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("All Directions") {
    HStack(spacing: 20) {
        ForEach(Direction.allCases, id: \.rawValue) { direction in
            VStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(direction.rotationAngle))
                Text("\(direction)".capitalized)
                    .font(.caption)
            }
        }
    }
    .padding()
}
