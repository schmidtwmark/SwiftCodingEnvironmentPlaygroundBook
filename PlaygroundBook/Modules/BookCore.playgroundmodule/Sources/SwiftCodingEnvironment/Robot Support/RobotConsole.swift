//
//  RobotConsole.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 2/1/26.
//

import SwiftUI
import PlaygroundSupport

// MARK: - Robot Actions

public enum RobotAction: String, Codable {
    case forward
    case turnRight
    case turnLeft
}

extension RobotAction: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .string(value) = playgroundValue,
              let action = RobotAction(rawValue: value) else {
            return nil
        }
        self = action
    }

    public var playgroundValue: PlaygroundValue {
        .string(rawValue)
    }
}

// MARK: - Commands (sent from student code to console)

public enum RobotSceneCommand {
    case loadLevel(Level)
    case robotAction(RobotAction)
    case reset
}

extension RobotSceneCommand: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .string(command)? = dict["Command"] else {
            return nil
        }

        switch command {
        case "LoadLevel":
            guard let levelValue = dict["Level"],
                  let level = Level(levelValue) else { return nil }
            self = .loadLevel(level)
        case "RobotAction":
            guard let actionValue = dict["Action"],
                  let action = RobotAction(actionValue) else { return nil }
            self = .robotAction(action)
        case "Reset":
            self = .reset
        default:
            return nil
        }
    }

    public var playgroundValue: PlaygroundValue {
        switch self {
        case .loadLevel(let level):
            return .dictionary([
                "Command": .string("LoadLevel"),
                "Level": level.playgroundValue
            ])
        case .robotAction(let action):
            return .dictionary([
                "Command": .string("RobotAction"),
                "Action": action.playgroundValue
            ])
        case .reset:
            return .dictionary([
                "Command": .string("Reset")
            ])
        }
    }
}

// MARK: - Responses (sent from console back to student code)

public enum RobotSceneResponse {
    case levelLoaded
    case actionCompleted(RobotAction)
    case actionFailed(RobotAction, LossReason)
    case won
}

extension RobotSceneResponse: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .string(command)? = dict["Command"] else {
            return nil
        }

        switch command {
        case "LevelLoaded":
            self = .levelLoaded
        case "ActionCompleted":
            guard let actionValue = dict["Action"],
                  let action = RobotAction(actionValue) else { return nil }
            self = .actionCompleted(action)
        case "ActionFailed":
            guard let actionValue = dict["Action"],
                  let action = RobotAction(actionValue),
                  let reasonValue = dict["Reason"],
                  let reason = LossReason(reasonValue) else { return nil }
            self = .actionFailed(action, reason)
        case "Won":
            self = .won
        default:
            return nil
        }
    }

    public var playgroundValue: PlaygroundValue {
        switch self {
        case .levelLoaded:
            return .dictionary([
                "Command": .string("LevelLoaded")
            ])
        case .actionCompleted(let action):
            return .dictionary([
                "Command": .string("ActionCompleted"),
                "Action": action.playgroundValue
            ])
        case .actionFailed(let action, let reason):
            return .dictionary([
                "Command": .string("ActionFailed"),
                "Action": action.playgroundValue,
                "Reason": reason.playgroundValue
            ])
        case .won:
            return .dictionary([
                "Command": .string("Won")
            ])
        }
    }
}

// MARK: - RobotConsole

@MainActor
public final class RobotConsole: BaseConsole<RobotConsole>, Console {

    @Published public var level: Level?
    @Published public var robotState: RobotState?
    @Published public var gameState: GameState = .playing

    private let animationDuration: Double = 0.3

    public var title: String { "Robot" }

    public var disableClear: Bool { false }

    public init(colorScheme: ColorScheme) {
        super.init()
    }

    public override func start(messageHandler: any PlaygroundLiveViewMessageHandler) {
        clear()
        super.start(messageHandler: messageHandler)
    }

    public override func clear() {
        super.clear()
        level = nil
        robotState = nil
        gameState = .playing
    }

    public func receive(_ message: PlaygroundValue) {
        guard let command = RobotSceneCommand(message) else { return }

        switch command {
        case .loadLevel(let newLevel):
            loadLevel(newLevel)
        case .robotAction(let action):
            Task {
                await performAction(action)
            }
        case .reset:
            resetLevel()
        }
    }

    // MARK: - Level Management

    private func loadLevel(_ newLevel: Level) {
        self.level = newLevel
        self.robotState = RobotState(
            position: newLevel.robotStart,
            direction: newLevel.robotDirection
        )
        self.gameState = .playing
        messageHandler?.send(RobotSceneResponse.levelLoaded.playgroundValue)
    }

    private func resetLevel() {
        guard let level = level else { return }
        self.robotState = RobotState(
            position: level.robotStart,
            direction: level.robotDirection
        )
        self.gameState = .playing
        messageHandler?.send(RobotSceneResponse.levelLoaded.playgroundValue)
    }

    // MARK: - Actions

    private func performAction(_ action: RobotAction) async {
        guard state == .running else { return }
        guard gameState == .playing else { return }
        guard var currentState = robotState, let level = level else { return }

        switch action {
        case .forward:
            let nextPosition = currentState.position.moved(in: currentState.direction)

            // Check for wall collision
            if isWallBlocking(from: currentState.position, direction: currentState.direction, in: level) {
                gameState = .lost(.hitWall)
                messageHandler?.send(RobotSceneResponse.actionFailed(action, .hitWall).playgroundValue)
                return
            }

            // Check for out of bounds
            if !isInBounds(nextPosition, in: level) {
                gameState = .lost(.outOfBounds)
                messageHandler?.send(RobotSceneResponse.actionFailed(action, .outOfBounds).playgroundValue)
                return
            }

            // Valid move - animate and update state
            currentState.position = nextPosition
            await animateRobotState(to: currentState)

            // Check for win
            if currentState.position == level.goalPosition {
                gameState = .won
                messageHandler?.send(RobotSceneResponse.won.playgroundValue)
                return
            }

        case .turnRight:
            currentState.direction = currentState.direction.turnedRight()
            await animateRobotState(to: currentState)

        case .turnLeft:
            currentState.direction = currentState.direction.turnedLeft()
            await animateRobotState(to: currentState)
        }

        messageHandler?.send(RobotSceneResponse.actionCompleted(action).playgroundValue)
    }

    private func animateRobotState(to newState: RobotState) async {
        // Use withCheckedContinuation for async animation similar to TurtleConsole
        await withCheckedContinuation { continuation in
            withAnimation(.easeInOut(duration: animationDuration)) {
                self.robotState = newState
            }
            // Wait for animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                continuation.resume()
            }
        }
    }

    // MARK: - Collision Detection

    private func isWallBlocking(from position: Position, direction: Direction, in level: Level) -> Bool {
        let wallSet = level.wallSet
        let nextPosition = position.moved(in: direction)
        let potentialWall = Wall(from: position, to: nextPosition)
        return wallSet.contains(potentialWall)
    }

    private func isInBounds(_ position: Position, in level: Level) -> Bool {
        return position.column >= 0 &&
               position.column < level.gridSize.columns &&
               position.row >= 0 &&
               position.row < level.gridSize.rows
    }
}
