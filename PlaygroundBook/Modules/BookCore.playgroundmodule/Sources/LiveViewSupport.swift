//
//  See LICENSE folder for this template’s licensing information.
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
    
    /**
     Rotate the turtle by the provided number of degrees
     */
    public func rotate(_ angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .rotate(angle)))
    }
    
    /**
     Move the turtle along an arc with provided radius for a given angle
     */
    public func arc(radius: Double, angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .arc(radius, angle)))
    }
    
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
    
}

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
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync { [unowned self] in
                self.sendCommand(command)
            }
        }
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return
        }
        
        liveViewMessageHandler.send(command)
    }
    
    @discardableResult func sendCommandAndWait(_ command: Request) -> Response {
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync { [unowned self] in
                return self.sendCommandAndWait(command)
            }
        }
        
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
        liveViewClient.sendCommandAndWait(.robotAction(.forward))
    }

    /**
     Rotate the robot 90 degrees to the right
     */
    public func turnRight() {
        liveViewClient.sendCommandAndWait(.robotAction(.turnRight))
    }

    /**
     Rotate the robot 90 degrees to the left
     */
    public func turnLeft() {
        liveViewClient.sendCommandAndWait(.robotAction(.turnLeft))
    }
}

public class RobotLiveViewClient : LiveViewClient<RobotSceneCommand, RobotSceneResponse> {

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
     Reset the current level to its initial state
     */
    public func reset() {
        sendCommandAndWait(.reset)
    }
}
