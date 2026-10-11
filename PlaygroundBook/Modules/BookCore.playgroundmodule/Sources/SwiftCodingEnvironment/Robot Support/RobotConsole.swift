//
//  RobotConsole.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 2/1/26.
//

import SwiftUI
import PlaygroundSupport

// MARK: - Robot Actions

public enum RobotAction: String, Codable, Sendable {
    case forward
    case turnRight
    case turnLeft
    case wait
}

extension RobotAction: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .string(value) = playgroundValue,
              let action = RobotAction(rawValue: value) else { return nil }
        self = action
    }
    public var playgroundValue: PlaygroundValue { .string(rawValue) }
}

// MARK: - Sensor Queries

/// Questions the student's code can ask about the robot. Asking never uses up a move,
/// so enemies and lasers do not advance while the robot "looks".
public enum RobotQuery: String, Codable, Sendable {
    case facingWall
    case isOnGoal
    case laserAhead

    /// The answer to use when there is no level or no reply: the one that makes a waiting
    /// loop (`while !robot.facingWall()`, `while !robot.isOnGoal()`, `while robot.laserAhead()`)
    /// stop instead of spinning.
    var stopLoopsAnswer: Bool {
        switch self {
        case .facingWall, .isOnGoal: return true
        case .laserAhead: return false
        }
    }
}

// MARK: - Commands

public enum RobotSceneCommand: Sendable {
    case loadLevel(Level)
    case getRobot
    case robotAction(RobotAction)
    case reset
    case query(RobotQuery)
}

extension RobotSceneCommand: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .string(command)? = dict["Command"] else { return nil }
        switch command {
        case "LoadLevel":
            guard let lv = dict["Level"], let level = Level(lv) else { return nil }
            self = .loadLevel(level)
        case "GetRobot": self = .getRobot
        case "RobotAction":
            guard let av = dict["Action"], let action = RobotAction(av) else { return nil }
            self = .robotAction(action)
        case "Reset": self = .reset
        case "Query":
            guard case let .string(q)? = dict["Query"], let query = RobotQuery(rawValue: q) else { return nil }
            self = .query(query)
        default: return nil
        }
    }

    public var playgroundValue: PlaygroundValue {
        switch self {
        case .loadLevel(let level):
            return .dictionary(["Command": .string("LoadLevel"), "Level": level.playgroundValue])
        case .getRobot:
            return .dictionary(["Command": .string("GetRobot")])
        case .robotAction(let action):
            return .dictionary(["Command": .string("RobotAction"), "Action": action.playgroundValue])
        case .reset:
            return .dictionary(["Command": .string("Reset")])
        case .query(let query):
            return .dictionary(["Command": .string("Query"), "Query": .string(query.rawValue)])
        }
    }
}

// MARK: - Responses

public enum RobotSceneResponse: Sendable {
    case levelLoaded
    case robotReady
    case actionCompleted(RobotAction)
    case actionFailed(RobotAction, LossReason)
    case won
    case queryResult(Bool)
}

extension RobotSceneResponse: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue,
              case let .string(command)? = dict["Command"] else { return nil }
        switch command {
        case "LevelLoaded": self = .levelLoaded
        case "RobotReady": self = .robotReady
        case "ActionCompleted":
            guard let av = dict["Action"], let a = RobotAction(av) else { return nil }
            self = .actionCompleted(a)
        case "ActionFailed":
            guard let av = dict["Action"], let a = RobotAction(av),
                  let rv = dict["Reason"], let r = LossReason(rv) else { return nil }
            self = .actionFailed(a, r)
        case "Won": self = .won
        case "QueryResult":
            guard case let .boolean(value)? = dict["Value"] else { return nil }
            self = .queryResult(value)
        default: return nil
        }
    }

    public var playgroundValue: PlaygroundValue {
        switch self {
        case .levelLoaded: return .dictionary(["Command": .string("LevelLoaded")])
        case .robotReady: return .dictionary(["Command": .string("RobotReady")])
        case .actionCompleted(let a):
            return .dictionary(["Command": .string("ActionCompleted"), "Action": a.playgroundValue])
        case .actionFailed(let a, let r):
            return .dictionary(["Command": .string("ActionFailed"), "Action": a.playgroundValue, "Reason": r.playgroundValue])
        case .won: return .dictionary(["Command": .string("Won")])
        case .queryResult(let value):
            return .dictionary(["Command": .string("QueryResult"), "Value": .boolean(value)])
        }
    }
}

// MARK: - RobotConsole

@MainActor
public final class RobotConsole: BaseConsole<RobotConsole>, Console, @unchecked Sendable {

    nonisolated(unsafe) public static var pendingLevel: Level?

    private var initialLevel: Level?

    @Published public var level: Level?
    @Published public var robotState: RobotState?
    @Published public var gameState: GameState = .playing
    @Published public var levelState: LevelState = LevelState()
    @Published public var moveCount: Int = 0

    private let animationDuration: Double = 0.3

    public var title: String { "Robot" }
    // No Clear while code is running: clearing mid-run would reset the board under a loop
    // that is still going. Students use Swift Playgrounds' Stop button instead.
    public var disableClear: Bool { state == .running }

    public init(colorScheme: ColorScheme) {
        super.init()
        if let pending = RobotConsole.pendingLevel {
            RobotConsole.pendingLevel = nil
            initialLevel = pending
            preloadLevel(pending)
        }
    }

    public override func start(messageHandler: any PlaygroundLiveViewMessageHandler) {
        resetToInitialLevel()
        super.start(messageHandler: messageHandler)
    }

    private func resetToInitialLevel() {
        super.clear()
        gameState = .playing
        levelState = LevelState()
        if let initial = initialLevel {
            preloadLevel(initial)
        } else {
            level = nil
            robotState = nil
        }
    }

    public override func clear() { resetToInitialLevel() }

    public func receive(_ message: PlaygroundValue) {
        guard let command = RobotSceneCommand(message) else { return }
        switch command {
        case .loadLevel(let newLevel): loadLevel(newLevel)
        case .getRobot: messageHandler?.send(RobotSceneResponse.robotReady.playgroundValue)
        case .robotAction(let action): Task { await performAction(action) }
        case .reset: resetLevel()
        case .query(let query):
            // Answered right away: looking does not move the robot or advance the tick.
            messageHandler?.send(RobotSceneResponse.queryResult(answer(query)).playgroundValue)
        }
    }

    // MARK: - Sensors

    private func answer(_ query: RobotQuery) -> Bool {
        guard let level = level, let robot = robotState else {
            return query.stopLoopsAnswer
        }
        let ahead = robot.position.moved(in: robot.direction)
        switch query {
        case .facingWall:
            // Walls and the edge of the map count. Doors, lasers and enemies do not.
            return !level.isInBounds(ahead) || level.cells[ahead.row][ahead.column] == .wall
        case .isOnGoal:
            return robot.position == level.goalPosition
        case .laserAhead:
            // True when stepping forward now would hit a laser. performAction checks the square
            // ahead at the current tick before moving, then checks again after the tick advances,
            // so a laser that is on now or turns on next tick both count.
            guard level.isInBounds(ahead) else { return false }
            return isLaserActive(at: ahead, in: level, tick: levelState.tick)
                || isLaserActive(at: ahead, in: level, tick: levelState.tick + 1)
        }
    }

    // MARK: - Run Result

    /// The page's code ended (it finished, crashed, or was stopped). Show how the level
    /// actually went in the status bar instead of a blanket "Success".
    public override func finish(_ newState: RunState) {
        guard newState == .success else {
            super.finish(newState)
            return
        }
        guard level != nil else {
            // e.g. a Custom Level map with no start or no flag stops the code before it loads
            super.finish(.failed("No level was loaded"))
            return
        }
        switch gameState {
        case .won:
            super.finish(.success)
        case .lost(let reason):
            super.finish(.failed(reason.rawValue))
        case .playing:
            super.finish(.failed("The robot didn't reach the flag"))
        }
    }

    // MARK: - Level Management

    public func preloadLevel(_ newLevel: Level) {
        self.level = newLevel
        self.robotState = RobotState(position: newLevel.robotStart, direction: newLevel.robotDirection)
        self.gameState = .playing
        self.levelState = LevelState()
        self.moveCount = 0
        self.levelState.enemyStates = newLevel.enemies.map {
            EnemyState(position: $0.startPosition, direction: $0.direction)
        }
    }

    private func loadLevel(_ newLevel: Level) {
        preloadLevel(newLevel)
        messageHandler?.send(RobotSceneResponse.levelLoaded.playgroundValue)
    }

    private func resetLevel() {
        guard let level = level else { return }
        preloadLevel(level)
        messageHandler?.send(RobotSceneResponse.levelLoaded.playgroundValue)
    }

    // MARK: - Actions

    private func performAction(_ action: RobotAction) async {
        guard state == .running, gameState == .playing,
              var currentState = robotState, let level = level else {
            // The student's code waits for a reply to every command, so always send one.
            // Without this, any command after a win or loss left the page "Running" forever.
            replyWithoutActing(action)
            return
        }
        moveCount += 1

        switch action {
        case .forward:
            let next = currentState.position.moved(in: currentState.direction)

            guard level.isInBounds(next) else { fail(action, .outOfBounds); return }
            guard level.cells[next.row][next.column] == .open else { fail(action, .hitWall); return }

            // Check closed doors
            if let doorResult = checkDoor(at: next, in: level) {
                if doorResult == .blocked { fail(action, .blockedByDoor); return }
            }

            // Check active lasers at current tick
            if isLaserActive(at: next, in: level, tick: levelState.tick) {
                fail(action, .hitLaser); return
            }

            // Move robot + advance tick simultaneously
            currentState.position = next
            await animateStepSimultaneously(robotState: currentState, level: level)

            // Post-move effects
            collectKeys(at: next, in: level)
            if let dest = checkTeleporter(at: next, in: level) {
                currentState.position = dest
                await animateRobotState(to: currentState)
            }

            if currentState.position == level.goalPosition {
                gameState = .won
                messageHandler?.send(RobotSceneResponse.won.playgroundValue)
                return
            }

            if checkPostTickDangers(at: currentState.position, in: level, action: action) { return }

        case .turnRight:
            currentState.direction = currentState.direction.turnedRight()
            await animateStepSimultaneously(robotState: currentState, level: level)
            if checkPostTickDangers(at: currentState.position, in: level, action: action) { return }

        case .turnLeft:
            currentState.direction = currentState.direction.turnedLeft()
            await animateStepSimultaneously(robotState: currentState, level: level)
            if checkPostTickDangers(at: currentState.position, in: level, action: action) { return }

        case .wait:
            await animateStepSimultaneously(robotState: currentState, level: level)
            if checkPostTickDangers(at: currentState.position, in: level, action: action) { return }
        }

        messageHandler?.send(RobotSceneResponse.actionCompleted(action).playgroundValue)
    }

    /// Answer a command the robot will not perform (the level is already won or lost,
    /// or the console is not running) so the waiting student code can keep going.
    private func replyWithoutActing(_ action: RobotAction) {
        switch gameState {
        case .won:
            messageHandler?.send(RobotSceneResponse.won.playgroundValue)
        case .lost(let reason):
            messageHandler?.send(RobotSceneResponse.actionFailed(action, reason).playgroundValue)
        case .playing:
            messageHandler?.send(RobotSceneResponse.actionCompleted(action).playgroundValue)
        }
    }

    private func fail(_ action: RobotAction, _ reason: LossReason) {
        gameState = .lost(reason)
        messageHandler?.send(RobotSceneResponse.actionFailed(action, reason).playgroundValue)
    }

    /// Returns true if robot died
    private func checkPostTickDangers(at position: Position, in level: Level, action: RobotAction) -> Bool {
        // Check enemies
        if levelState.enemyStates.contains(where: { $0.position == position }) {
            fail(action, .caughtByEnemy); return true
        }
        // Check lasers that may have turned on after tick advance
        if isLaserActive(at: position, in: level, tick: levelState.tick) {
            fail(action, .hitLaser); return true
        }
        return false
    }

    // MARK: - Animation

    /// Animate robot state change, enemy movement, and tick advance all at once.
    private func animateStepSimultaneously(robotState newState: RobotState, level: Level) async {
        await withCheckedContinuation { continuation in
            withAnimation(.easeInOut(duration: animationDuration)) {
                self.robotState = newState
                self.levelState.tick += 1
                self.advanceEnemies(in: level)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { continuation.resume() }
        }
    }

    /// Animate only the robot (used for teleportation jump, no tick advance).
    private func animateRobotState(to newState: RobotState) async {
        await withCheckedContinuation { continuation in
            withAnimation(.easeInOut(duration: animationDuration)) { self.robotState = newState }
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { continuation.resume() }
        }
    }

    // MARK: - Enemy Bounce AI

    private func advanceEnemies(in level: Level) {
        for i in levelState.enemyStates.indices {
            let state = levelState.enemyStates[i]
            let next = state.position.moved(in: state.direction)

            if isEnemyPassable(next, in: level) {
                levelState.enemyStates[i].position = next
            } else {
                let reversed = state.direction.reversed()
                levelState.enemyStates[i].direction = reversed
                let bounceNext = state.position.moved(in: reversed)
                if isEnemyPassable(bounceNext, in: level) {
                    levelState.enemyStates[i].position = bounceNext
                }
            }
        }
    }

    private func isEnemyPassable(_ position: Position, in level: Level) -> Bool {
        guard level.isInBounds(position) else { return false }
        guard level.cells[position.row][position.column] == .open else { return false }
        for (i, door) in level.doors.enumerated() where door.position == position {
            if !levelState.openDoors.contains(i) { return false }
        }
        if isLaserActive(at: position, in: level, tick: levelState.tick) { return false }
        return true
    }

    // MARK: - Laser Logic (tick-based)

    private func isLaserActive(at position: Position, in level: Level, tick: Int) -> Bool {
        for laser in level.lasers where laser.position == position {
            if laser.isActive(at: tick) { return true }
        }
        return false
    }

    // MARK: - Key & Door Logic (keys only open doors, NOT lasers)

    private func collectKeys(at position: Position, in level: Level) {
        for (index, key) in level.keys.enumerated() {
            if key.position == position && !levelState.collectedKeys.contains(index) {
                _ = withAnimation(.easeOut(duration: 0.2)) {
                    levelState.collectedKeys.insert(index)
                }
                // Open matching doors
                for (doorIndex, door) in level.doors.enumerated() {
                    if door.color == key.color && !levelState.openDoors.contains(doorIndex) {
                        _ = withAnimation(.easeOut(duration: 0.2)) {
                            levelState.openDoors.insert(doorIndex)
                        }
                    }
                }
            }
        }
    }

    private enum DoorCheckResult { case blocked, opened }

    private func checkDoor(at position: Position, in level: Level) -> DoorCheckResult? {
        for (index, door) in level.doors.enumerated() {
            guard door.position == position && !levelState.openDoors.contains(index) else { continue }
            let hasKey = level.keys.enumerated().contains { keyIndex, key in
                key.color == door.color && levelState.collectedKeys.contains(keyIndex)
            }
            if hasKey {
                _ = withAnimation(.easeOut(duration: 0.2)) { levelState.openDoors.insert(index) }
                return .opened
            }
            return .blocked
        }
        return nil
    }

    // MARK: - Teleporter

    private func checkTeleporter(at position: Position, in level: Level) -> Position? {
        for teleporter in level.teleporters {
            if let dest = teleporter.destination(from: position) { return dest }
        }
        return nil
    }
}
