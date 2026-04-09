//
//  RobotConsoleView.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 2/1/26.
//

import SwiftUI

// MARK: - Cell Display State

enum CellDisplayState: Equatable {
    case wall
    case open
    case goal
    case door(color: Color, isOpen: Bool)
    case key(color: Color)
    case laser(color: Color, isActive: Bool, orientation: LaserOrientation)
    case teleporter(color: Color)
}

// MARK: - RobotConsoleView

public struct RobotConsoleView: ConsoleView {

    @ObservedObject public var console: RobotConsole
    @Environment(\.colorScheme) var colorScheme

    public init(console: RobotConsole) {
        self.console = console
    }

    public var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            if let level = console.level, let robotState = console.robotState {
                GridView(
                    level: level,
                    robotState: robotState,
                    gameState: console.gameState,
                    levelState: console.levelState,
                    moveCount: console.moveCount
                )
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
        }
    }

    private var backgroundColor: Color {
        Color(white: 0.25)
    }
}

// MARK: - GridView

struct GridView: View {
    let level: Level
    let robotState: RobotState
    let gameState: GameState
    let levelState: LevelState
    var moveCount: Int = 0

    private var cellSize: CGFloat {
        let maxDim = max(level.rows, level.columns)
        if maxDim <= 7 { return 50 }
        if maxDim <= 9 { return 44 }
        if maxDim <= 11 { return 38 }
        if maxDim <= 13 { return 32 }
        return 28
    }

    var body: some View {
        let gridWidth = CGFloat(level.columns) * cellSize
        let gridHeight = CGFloat(level.rows) * cellSize

        ZStack(alignment: .bottom) {
            ZStack(alignment: .topLeading) {
                // Cells
                VStack(spacing: 0) {
                    ForEach(0..<level.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<level.columns, id: \.self) { column in
                                CellView(
                                    state: displayState(at: Position(column: column, row: row)),
                                    cellSize: cellSize
                                )
                            }
                        }
                    }
                }

                // Keys (uncollected)
                ForEach(Array(level.keys.enumerated()), id: \.offset) { index, key in
                    if !levelState.collectedKeys.contains(index) {
                        KeyView(key: key, cellSize: cellSize)
                    }
                }

                // Enemies
                ForEach(Array(levelState.enemyStates.enumerated()), id: \.offset) { _, enemyState in
                    EnemyView(position: enemyState.position, cellSize: cellSize)
                }

                // Robot
                RobotView(
                    position: robotState.position,
                    direction: robotState.direction,
                    cellSize: cellSize,
                    isLost: gameState != .playing && gameState != .won
                )
            }
            .frame(width: gridWidth, height: gridHeight)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Color tint overlay
            if case .won = gameState {
                Color.green.opacity(0.3)
                    .frame(width: gridWidth, height: gridHeight)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if case .lost = gameState {
                Color.red.opacity(0.3)
                    .frame(width: gridWidth, height: gridHeight)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Result banner
            if case .won = gameState {
                WinBanner(moveCount: moveCount, par: level.minimumMoves)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if case .lost(let reason) = gameState {
                LoseBanner(reason: reason)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Collected keys HUD
            if !level.keys.isEmpty {
                CollectedKeysHUD(level: level, levelState: levelState, gridWidth: gridWidth)
            }
        }
        .frame(width: gridWidth, height: gridHeight)
    }

    private func displayState(at position: Position) -> CellDisplayState {
        let cell = level.cells[position.row][position.column]
        if cell == .wall { return .wall }

        if position == level.goalPosition { return .goal }

        for (i, door) in level.doors.enumerated() where door.position == position {
            return .door(color: elementColor(door.color), isOpen: levelState.openDoors.contains(i))
        }

        // Show key cells as open (key icon rendered separately)
        for (i, key) in level.keys.enumerated() where key.position == position {
            if !levelState.collectedKeys.contains(i) { return .key(color: elementColor(key.color)) }
        }

        for laser in level.lasers where laser.position == position {
            return .laser(color: elementColor(laser.color),
                          isActive: laser.isActive(at: levelState.tick),
                          orientation: laser.orientation)
        }

        for tp in level.teleporters where tp.from == position || tp.to == position {
            return .teleporter(color: elementColor(tp.color))
        }

        return .open
    }
}

// MARK: - CellView

struct CellView: View {
    let state: CellDisplayState
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: cellSize, height: cellSize)

            if state != .wall {
                Rectangle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                    .frame(width: cellSize, height: cellSize)
            }

            switch state {
            case .goal:
                Image(systemName: "flag.fill")
                    .font(.system(size: cellSize * 0.4))
                    .foregroundColor(.green)
            case .door(_, let isOpen):
                if !isOpen {
                    Image(systemName: "lock.fill")
                        .font(.system(size: cellSize * 0.3))
                        .foregroundColor(.white)
                }
            case .laser(let color, let isActive, let orientation):
                if isActive {
                    if orientation == .horizontal || orientation == .cross {
                        Rectangle()
                            .fill(color)
                            .frame(width: cellSize, height: 3)
                    }
                    if orientation == .vertical || orientation == .cross {
                        Rectangle()
                            .fill(color)
                            .frame(width: 3, height: cellSize)
                    }
                    Circle()
                        .fill(color.opacity(0.6))
                        .frame(width: cellSize * 0.2, height: cellSize * 0.2)
                        .shadow(color: color, radius: 4)
                }
            case .teleporter(let color):
                Image(systemName: "circle.dotted")
                    .font(.system(size: cellSize * 0.5))
                    .foregroundColor(color.opacity(0.7))
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }

    private var backgroundColor: Color {
        switch state {
        case .wall:
            return Color(white: 0.25)
        case .open, .key:
            return Color(white: 0.92)
        case .goal:
            return Color.green.opacity(0.25)
        case .door(let color, let isOpen):
            return isOpen ? Color(white: 0.92) : color.opacity(0.7)
        case .laser(let color, let isActive, _):
            return isActive ? color.opacity(0.15) : Color(white: 0.92)
        case .teleporter:
            return Color.purple.opacity(0.08)
        }
    }
}

// MARK: - KeyView

struct KeyView: View {
    let key: Key
    let cellSize: CGFloat

    var body: some View {
        let xPos = CGFloat(key.position.column) * cellSize + cellSize / 2
        let yPos = CGFloat(key.position.row) * cellSize + cellSize / 2

        Image(systemName: "key.fill")
            .font(.system(size: cellSize * 0.35))
            .foregroundColor(elementColor(key.color))
            .shadow(color: elementColor(key.color).opacity(0.5), radius: 3)
            .position(x: xPos, y: yPos)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - EnemyView

struct EnemyView: View {
    let position: Position
    let cellSize: CGFloat

    var body: some View {
        let xPos = CGFloat(position.column) * cellSize + cellSize / 2
        let yPos = CGFloat(position.row) * cellSize + cellSize / 2

        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: cellSize * 0.4))
            .foregroundColor(.red)
            .shadow(color: .red.opacity(0.5), radius: 3)
            .position(x: xPos, y: yPos)
            .animation(.easeInOut(duration: 0.3), value: position.column)
            .animation(.easeInOut(duration: 0.3), value: position.row)
    }
}

// MARK: - RobotView

struct RobotView: View {
    let position: Position
    let direction: Direction
    let cellSize: CGFloat
    let isLost: Bool

    var body: some View {
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

// MARK: - Collected Keys HUD

struct CollectedKeysHUD: View {
    let level: Level
    let levelState: LevelState
    let gridWidth: CGFloat

    var body: some View {
        VStack {
            HStack(spacing: 4) {
                Spacer()
                ForEach(Array(level.keys.enumerated()), id: \.offset) { index, key in
                    Image(systemName: levelState.collectedKeys.contains(index) ? "key.fill" : "key")
                        .font(.system(size: 14))
                        .foregroundColor(
                            levelState.collectedKeys.contains(index)
                                ? elementColor(key.color) : .gray.opacity(0.5)
                        )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))
            .padding(.top, 4)
            .padding(.trailing, 4)
            .frame(width: gridWidth, alignment: .trailing)
            Spacer()
        }
    }
}

// MARK: - Win Banner

struct WinBanner: View {
    let moveCount: Int
    let par: Int?

    private var isPerfect: Bool {
        guard let par = par else { return true }
        return moveCount <= par
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isPerfect ? "star.fill" : "checkmark.circle.fill")
                .font(.title)
                .foregroundColor(isPerfect ? .yellow : .white)
                .shadow(color: isPerfect ? .orange : .clear, radius: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(isPerfect ? "Perfect!" : "You Win!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                if let par = par, !isPerfect {
                    Text("Completed in \(moveCount) moves — can you do it in \(par)?")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("\(moveCount) moves")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(isPerfect ? Color.green : Color.orange).shadow(color: .black.opacity(0.3), radius: 8))
    }
}

// MARK: - Lose Banner

struct LoseBanner: View {
    let reason: LossReason

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Game Over")
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                Text(reason.rawValue)
                    .font(.caption).foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.red).shadow(color: .black.opacity(0.3), radius: 8))
    }
}

// MARK: - Previews

#Preview("Simple") {
    GridView(level: PreviewLevels.simple,
             robotState: RobotState(position: Position(column: 1, row: 1), direction: .north),
             gameState: .playing, levelState: LevelState()).padding()
}

#Preview("Lasers") {
    GridView(level: PreviewLevels.withLasers,
             robotState: RobotState(position: Position(column: 1, row: 1), direction: .north),
             gameState: .playing, levelState: LevelState()).padding()
}

#Preview("Won") {
    GridView(level: PreviewLevels.simple,
             robotState: RobotState(position: Position(column: 3, row: 3), direction: .north),
             gameState: .won, levelState: LevelState(), moveCount: 6).padding()
}

#Preview("Lost") {
    GridView(level: PreviewLevels.withWalls,
             robotState: RobotState(position: Position(column: 2, row: 2), direction: .north),
             gameState: .lost(.hitWall), levelState: LevelState()).padding()
}
