//
//  See LICENSE folder for this template's licensing information.
//
//  Abstract:
//  Provides supporting functions for setting up a live view.
//

import UIKit
import PlaygroundSupport
import SwiftUI

public class TextLiveViewClient : LiveViewClient<TextCommand, TextResponse> {

    /**
     Write the provided string to the console
     */
    public func write(_ text: String) {
        sendCommand(TextCommand.write(text))
    }

    /**
     Write the provided colored string to the console.
     */
    public func write(_ coloredText: ColoredString) {
        sendCommand(TextCommand.writeColor(coloredText))
    }

    /**
     Write the provided prompt to the console, wait for the user to enter a response, return the response
     */
    public func read(_ prompt: String) -> String {
        let response = sendCommandAndWait(.read(prompt))
        if case let .submit(text) = response {
            return text
        } else {
            return ""
        }
    }
}

/// A number a turtle command accepts: a whole number like `50` or `size`, or a decimal like `22.5`.
/// Every turtle command takes `Double`; these let `Int` variables work too, as in `turtle.forward(size)`.
public protocol TurtleNumber {
    var turtleValue: Double { get }
}
extension Int: TurtleNumber {
    public var turtleValue: Double { Double(self) }
}
extension Double: TurtleNumber {
    public var turtleValue: Double { self }
}

public class TurtleHandle {
    let liveViewClient: TurtleLiveViewClient
    let id: UUID

    init(liveViewClient: TurtleLiveViewClient, id: UUID) {
        self.liveViewClient = liveViewClient
        self.id = id
    }

    /**
     Move the turtle forward the specified distance
     */
    public func forward(_ distance: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .forward(distance)))
    }

    /**
     Move the turtle backward the specified distance
     */
    public func backward(_ distance: Double) {
        forward(-distance)
    }

    // Students always say which way: rotateLeft/rotateRight, arcLeft/arcRight, ovalLeft/ovalRight.
    // These send the turn; a positive angle turns left (counterclockwise).
    private func sendRotate(_ angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .rotate(angle)))
    }

    private func sendArc(radius: Double, angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .arc(radius, angle)))
    }

    // xRadius is along the turtle's heading; yRadius is to the side (the distance to the oval's center).
    private func sendOval(xRadius: Double, yRadius: Double, angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .oval(xRadius, yRadius, angle)))
    }

    // The plain rotate, arc and oval are gone, so a student who types them (from an old example or an AI
    // suggestion) gets a message saying what to use instead. They also don't appear in autocomplete.
    @available(*, unavailable, message: "Say which way to turn: use turtle.rotateLeft(_:) or turtle.rotateRight(_:)")
    public func rotate(_ angle: Double) {}
    @available(*, unavailable, message: "Say which way to turn: use turtle.rotateLeft(_:) or turtle.rotateRight(_:)")
    @_disfavoredOverload public func rotate<N: TurtleNumber>(_ angle: N) {}
    @available(*, unavailable, message: "Say which way to curve: use turtle.arcLeft(radius:angle:) or turtle.arcRight(radius:angle:)")
    public func arc(radius: Double, angle: Double) {}
    @available(*, unavailable, message: "Say which way to curve: use turtle.arcLeft(radius:angle:) or turtle.arcRight(radius:angle:)")
    @_disfavoredOverload public func arc<R: TurtleNumber, A: TurtleNumber>(radius: R, angle: A) {}
    @available(*, unavailable, message: "Say which way to curve: use turtle.ovalLeft(xRadius:yRadius:angle:) or turtle.ovalRight(xRadius:yRadius:angle:)")
    public func oval(xRadius: Double, yRadius: Double, angle: Double) {}
    @available(*, unavailable, message: "Say which way to curve: use turtle.ovalLeft(xRadius:yRadius:angle:) or turtle.ovalRight(xRadius:yRadius:angle:)")
    @_disfavoredOverload public func oval<X: TurtleNumber, Y: TurtleNumber, A: TurtleNumber>(xRadius: X, yRadius: Y, angle: A) {}

    /**
     Stop drawing lines
     */
    public func penUp() {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .penUp))
    }

    /**
     Draw a line that traces the path of the turtle. Optionally specify a color to fill
     */
    public func penDown(fillColor: Color = .clear) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .penDown(fillColor)))
    }

    /**
     Change the color of the line
     */
    public func lineColor(_ color: Color) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .lineColor(color)))
    }

    /**
     Change the width of the line
     */
    public func lineWidth(_ width: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .lineWidth(width)))
    }

    /**
     Turn left (counterclockwise) by the provided number of degrees
     */
    public func rotateLeft(_ angle: Double) {
        sendRotate(angle)
    }

    /**
     Turn right (clockwise) by the provided number of degrees
     */
    public func rotateRight(_ angle: Double) {
        sendRotate(-angle)
    }

    /**
     Move along a circle with the provided radius for `angle` degrees, curving to the left
     */
    public func arcLeft(radius: Double, angle: Double) {
        sendArc(radius: radius, angle: angle)
    }

    /**
     Move along a circle with the provided radius for `angle` degrees, curving to the right
     */
    public func arcRight(radius: Double, angle: Double) {
        sendArc(radius: radius, angle: -angle)
    }

    /**
     Move along an oval for `angle` degrees, curving to the left.
     `xRadius` is along the turtle's heading; `yRadius` is to the side.
     */
    public func ovalLeft(xRadius: Double, yRadius: Double, angle: Double) {
        sendOval(xRadius: xRadius, yRadius: yRadius, angle: angle)
    }

    /**
     Move along an oval for `angle` degrees, curving to the right.
     `xRadius` is along the turtle's heading; `yRadius` is to the side.
     */
    public func ovalRight(xRadius: Double, yRadius: Double, angle: Double) {
        sendOval(xRadius: xRadius, yRadius: yRadius, angle: -angle)
    }

    /**
     Change the color of the whole canvas behind the drawing. It goes back to light gray on the next run.
     */
    public func backgroundColor(_ color: Color) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .backgroundColor(color)))
    }

    /**
     Hide the turtle, for a clean finished picture
     */
    public func hideTurtle() {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .visible(false)))
    }

    /**
     Show the turtle again after `hideTurtle()`
     */
    public func showTurtle() {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .visible(true)))
    }

    /**
     Move in a straight line to a spot, keeping the same heading. The turtle starts at x: 0, y: 0;
     x goes up to the right and y goes up toward the top. Draws a line if the pen is down.
     */
    public func goTo(x: Double, y: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .goTo(x, y)))
    }

    /**
     Turn to face a direction: 0 is right, 90 is up, 180 is left, and 270 (or -90) is down
     */
    public func setHeading(_ angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .setHeading(angle)))
    }

    /**
     Go back to where the turtle started (x: 0, y: 0) and face right. Draws a line if the pen is down.
     */
    public func home() {
        goTo(x: 0, y: 0)
        setHeading(0)
    }

    // Whole-number versions, so Int variables work (`turtle.forward(size)`). They are disfavored, so a
    // call with plain numbers still uses the Double version: `rotateLeft(360 / 7)` turns 51.43, not 51.
    // Autocomplete lists them next to the Double versions, so they get the same descriptions.
    /// Move the turtle forward the specified distance. Works with whole numbers too.
    @_disfavoredOverload public func forward<N: TurtleNumber>(_ distance: N) { forward(distance.turtleValue) }
    /// Move the turtle backward the specified distance. Works with whole numbers too.
    @_disfavoredOverload public func backward<N: TurtleNumber>(_ distance: N) { backward(distance.turtleValue) }
    /// Change the width of the line. Works with whole numbers too.
    @_disfavoredOverload public func lineWidth<N: TurtleNumber>(_ width: N) { lineWidth(width.turtleValue) }
    /// Move in a straight line to a spot, keeping the same heading. The turtle starts at x: 0, y: 0. Works with whole numbers too.
    @_disfavoredOverload public func goTo<X: TurtleNumber, Y: TurtleNumber>(x: X, y: Y) { goTo(x: x.turtleValue, y: y.turtleValue) }
    /// Turn to face a direction: 0 is right, 90 is up, 180 is left, and 270 (or -90) is down. Works with whole numbers too.
    @_disfavoredOverload public func setHeading<N: TurtleNumber>(_ angle: N) { setHeading(angle.turtleValue) }
    /// Turn left (counterclockwise) by the provided number of degrees. Works with whole numbers too.
    @_disfavoredOverload public func rotateLeft<N: TurtleNumber>(_ angle: N) { rotateLeft(angle.turtleValue) }
    /// Turn right (clockwise) by the provided number of degrees. Works with whole numbers too.
    @_disfavoredOverload public func rotateRight<N: TurtleNumber>(_ angle: N) { rotateRight(angle.turtleValue) }
    /// Move along a circle for `angle` degrees, curving to the left. Works with whole numbers too.
    @_disfavoredOverload public func arcLeft<R: TurtleNumber, A: TurtleNumber>(radius: R, angle: A) {
        arcLeft(radius: radius.turtleValue, angle: angle.turtleValue)
    }
    /// Move along a circle for `angle` degrees, curving to the right. Works with whole numbers too.
    @_disfavoredOverload public func arcRight<R: TurtleNumber, A: TurtleNumber>(radius: R, angle: A) {
        arcRight(radius: radius.turtleValue, angle: angle.turtleValue)
    }
    /// Move along an oval for `angle` degrees, curving to the left. Works with whole numbers too.
    @_disfavoredOverload public func ovalLeft<X: TurtleNumber, Y: TurtleNumber, A: TurtleNumber>(xRadius: X, yRadius: Y, angle: A) {
        ovalLeft(xRadius: xRadius.turtleValue, yRadius: yRadius.turtleValue, angle: angle.turtleValue)
    }
    /// Move along an oval for `angle` degrees, curving to the right. Works with whole numbers too.
    @_disfavoredOverload public func ovalRight<X: TurtleNumber, Y: TurtleNumber, A: TurtleNumber>(xRadius: X, yRadius: Y, angle: A) {
        ovalRight(xRadius: xRadius.turtleValue, yRadius: yRadius.turtleValue, angle: angle.turtleValue)
    }
}

/// Base class for live view clients that communicate with the console via PlaygroundValue messages.
/// All methods run synchronously on the main thread using RunLoop spinning to wait for responses.
public class LiveViewClient<Request: ConsoleMessage, Response: ConsoleMessage> : PlaygroundRemoteLiveViewProxyDelegate {

    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundSupport.PlaygroundRemoteLiveViewProxy) {
    }

    public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundSupport.PlaygroundRemoteLiveViewProxy, received message: PlaygroundSupport.PlaygroundValue) {
        guard let response = Response(message) else {
            return
        }
        responses.append(response)
    }

    func sendCommand(_ command: Request) {
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return
        }

        liveViewMessageHandler.send(command)
    }

    @discardableResult func sendCommandAndWait(_ command: Request) -> Response {
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            fatalError("Could not find live view")
        }

        liveViewMessageHandler.delegate = self
        liveViewMessageHandler.send(command)
        repeat {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        } while responses.count == 0

        return responses.remove(at: 0)
    }

    var responses: [Response] = []

    public init() { }
}

public class TurtleLiveViewClient : LiveViewClient<TurtleSceneCommand, TurtleSceneResponse> {

    /**
     Add a new turtle to the screen
     */
    public func addTurtle() -> TurtleHandle {
        let result = sendCommandAndWait(.addTurtle)
        if case .added(let id) = result {
            return TurtleHandle(liveViewClient: self, id: id)
        } else {
            fatalError("Failed to add turtle")
        }
    }
}

// MARK: - Robot Support

public class RobotHandle {
    let liveViewClient: RobotLiveViewClient

    init(liveViewClient: RobotLiveViewClient) {
        self.liveViewClient = liveViewClient
    }

    /**
     Move the robot forward one cell in its current direction
     */
    public func forward() {
        perform(.forward)
    }

    /**
     Rotate the robot 90 degrees to the right
     */
    public func turnRight() {
        perform(.turnRight)
    }

    /**
     Rotate the robot 90 degrees to the left
     */
    public func turnLeft() {
        perform(.turnLeft)
    }

    /**
     Wait one turn without moving (enemies and traps still advance)
     */
    public func wait() {
        perform(.wait)
    }

    /**
     True if the square right in front of the robot is a wall or the edge of the map.
     Looking does not use up a move.
     */
    public func facingWall() -> Bool {
        ask(.facingWall)
    }

    /**
     True if the square right in front of the robot is not a wall or the edge of the map:
     the exact opposite of `facingWall()`. Lets `while robot.facingEmptySpace() { robot.forward() }`
     be taught before `!`. Looking does not use up a move.
     */
    public func facingEmptySpace() -> Bool {
        !facingWall()
    }

    /**
     True if the robot is standing on the flag. Looking does not use up a move.
     */
    public func isOnGoal() -> Bool {
        ask(.isOnGoal)
    }

    /**
     True if there's a laser in the square right in front of the robot that is on, or about to
     turn on. `while robot.laserAhead() { robot.wait() }` waits until it's safe to step forward.
     Looking does not use up a move.
     */
    public func laserAhead() -> Bool {
        ask(.laserAhead)
    }

    private func perform(_ action: RobotAction) {
        switch liveViewClient.sendCommandAndWait(.robotAction(action)) {
        case .won, .actionFailed:
            // The level is over, so end the run. Loops like
            // `while !robot.isOnGoal()` stop at the flag or the crash
            // instead of spinning forever.
            PlaygroundPage.current.finishExecution()
        default:
            break
        }
    }

    private func ask(_ query: RobotQuery) -> Bool {
        if case .queryResult(let value) = liveViewClient.sendCommandAndWait(.query(query)) {
            return value
        }
        // Unexpected reply: answer so that a waiting loop stops instead of spinning.
        return query.stopLoopsAnswer
    }
}

public class RobotLiveViewClient : LiveViewClient<RobotSceneCommand, RobotSceneResponse> {

    /**
     Get a handle to control the robot (for pre-loaded levels)
     */
    public func robot() -> RobotHandle {
        let result = sendCommandAndWait(.getRobot)
        if case .robotReady = result {
            return RobotHandle(liveViewClient: self)
        } else {
            fatalError("Robot not ready - ensure level is pre-loaded in LiveView.swift")
        }
    }

    /**
     Load a level and return a handle to control the robot
     */
    public func loadLevel(_ level: Level) -> RobotHandle {
        let result = sendCommandAndWait(.loadLevel(level))
        if case .levelLoaded = result {
            return RobotHandle(liveViewClient: self)
        } else {
            fatalError("Failed to load level")
        }
    }

    /**
     Load a level from an ASCII string and return a handle to control the robot
     */
    @discardableResult
    public func loadLevel(_ ascii: String) -> RobotHandle {
        return loadLevel(Level.ascii(ascii))
    }

    /**
     Reset the current level to its initial state
     */
    public func reset() {
        sendCommandAndWait(.reset)
    }
}
